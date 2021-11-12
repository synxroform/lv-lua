local lcpp = require("premake5_lcpp")


-- change this table if you want to remove/add 
-- functionality from/to public api 

local filter = {
  ["lv_obj.h"] = true,
  ["lv_obj_pos.h"] = true,
  ["lv_btn.h"] = true,
  ["lv_disp.h"] = true,
  ["lv_event.h"] = true,
  ["lv_label.h"] = true,
}

local globvars = {} -- #define variables  
local typedefs = {} -- lvgl typedefs
local calldefs = {} -- lvgl typedefs for callbacks
local api_proc = {} -- lvgl functions
local sp_table = lcpp.getSpecifierTable({})


-- some structures cannot be tracked down to definition
local bug_fix = {

lv_color_t = function()
  if globvars["LV_COLOR_DEPTH"] == 1 then
    local s = "union { uint8_t b:1; uint8_t g:1; uint8_t r:1; } ch;"
    typedefs["lv_color_t"] = "typedef union{uint8_t full; " .. s .. "} lv_color_t;"
  end
  if globvars["LV_COLOR_DEPTH"] == 8 then
    local s = "struct { uint8_t b:2; uint8_t g:3; uint8_t r:3; } ch"
    typedefs["lv_color_t"] = "typedef union{ " .. s .. "; uint8_t full;} lv_color_t;"
  end
  if globvars["LV_COLOR_DEPTH"] == 16 then
    local s = "struct { uint16_t b:5; uint16_t g:6; uint16_t r:5; } ch"
    typedefs["lv_color_t"] = "typedef union{ " .. s .. "; uint16_t full;} lv_color_t;"
  end
  if globvars["LV_COLOR_DEPTH"] == 32 then
    local s = "struct { uint8_t b; uint8_t g; uint8_t r; uint8_t a; } ch"
    typedefs["lv_color_t"] = "typedef union{ " .. s .. "; uint32_t full;} lv_color_t;"
  end
end,

lv_point_t = function()
  local ct = globvars["LV_USE_LARGE_COORD"] == 1 and "int32_t" or "int16_t"
  typedefs["lv_point_t"] = "typedef struct {" .. ct .. " x; " .. ct .. " y;} lv_point_t;"
end

}

function file_from_where(path)
    return path:match(".*:"):sub(1,-2):match("[%w_%.]*$")
end

function decl_to_str(decl)
  return lcpp.declToString(decl):gsub("%[typetag%]%s", "") .. ";"
end

function enumerate_include_dirs(opts)
  local set = {}
  for _, v in pairs(os.matchfiles("lvgl/src/**.h")) do
    local dir = v:match(".*/"):sub(1,-2)
    if not set[dir] then
      set[dir] = true
      table.insert(opts, "-I " .. dir)
    end
  end
end


function trim_struct(arg)
  if arg.tag == "Type" and arg.n:match("^struct") then
    arg.n = arg.n:match("[%w_]*$")
  end
  if arg.tag == "Qualified" and arg.t.n:match("^struct") then
    arg.t.n = arg.t.n:match("[%w_]*$")
  end
end

function is_callback(t)
  return  t.tag == "Pointer" and t.t.tag == "Function" 
end

function extract_typedef(arg)
    local typ = arg
    while typ.tag ~= "Type" do
      typ = typ.t
    end
    local tname = typ.n:match("[%w_]*$") 
    if not typedefs[tname] and not calldefs[tname] then
      -- pointers converted to void*
      if arg.tag == "Pointer" and not sp_table[tname] then
        typ.n = tname
        typedefs[tname] = "typedef void " .. tname .. ";"
      end
      
      -- callbacks, enumerations and simple structures
      if arg.tag == "Type" and arg._def then
        if arg._def.tag == "Enum" then
          typedefs[tname] = "typedef uint32_t " .. tname .. ";" 
        end
        if arg._def.tag == "Type" then
          typedefs[tname] = "typedef " .. arg._def.n .. " " .. tname .. ";"
        end
        if is_callback(arg._def) then
          local s = lcpp.typeToString(arg._def, tname)
          calldefs[tname] = "typedef " .. s .. ";"
        end
      end
      
      -- rewrite automatic typedef with custom one
      if bug_fix[tname] then bug_fix[tname]() end
    end 
end

function process_func(f) 
  for k, v in ipairs(f) do
    if v[1] then
      extract_typedef(v[1])
    end
  end
  extract_typedef(f.t)
end

function write_api_file()
  local af = io.open("main_api.c", "w+")
  for ln in io.lines("main_api.c.x") do
    if ln == "DO_DECL" then
      for _, decl in ipairs(api_proc) do
        af:write("{ &" .. decl.n .. ", \"" .. decl.d .. "\" },\n")
      end
      goto continue
    end
    if ln == "DO_CDEF" then
      for _, tab in pairs({typedefs, calldefs}) do
        for _, def in pairs(tab) do
          af:write("\"" .. def .. "\"\n")
        end
      end
      af:seek("cur", -1)
      af:write(";\n")
      goto continue
    end
    af:write(ln .. "\n")
    ::continue::
  end
  af:close()
end

function parse_config()
  for d in lcpp.declarationIterator({"-w"}, io.lines("lv_conf.h"), "") do
    if d.tag == "CppEvent" and d.directive == "define" then
      globvars[d.name] = d.intval
    end
  end
end


function get_public_api(header, opts)
  local phase = 0
  for d in lcpp.declarationIterator(opts, io.lines(header), "") do
    local file = file_from_where(d.where)
    if phase == 0 then 
      io.write("*") 
    end
    phase = (phase + 1) % 100
    if filter[file] then
      if d.tag == "Declaration" or d.tag == "Definition" then
        if d.type.tag == "Function" then
          if d.tag == "Definition" then
            d.sclass = nil
            d.init = nil
            d.type.inline = false
          end
          local dn = d.name
          d.name = d.name:gsub("^[%w_]%w*_", "")
          process_func(d.type)
          table.insert(api_proc, {n = dn, d = decl_to_str(d)})
        end
      end
    end
  end
  write_api_file()
end


function bind_lvgl()
  local opts = {"-std=gnu11", "-w", "-DAPI_GENERATOR", "-I lvgl", "-I lvgl/src"}
  enumerate_include_dirs(opts)
  parse_config()
  get_public_api("lvgl/lvgl.h", opts)
end


newaction {
  trigger = "bind",
  description = "make api bindings",
  onStart = function ()
    bind_lvgl()
  end,
}
