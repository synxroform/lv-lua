--[[
premake.modules.sync = {}
local m = premake.modules.sync
local p = premake
]]--

local web_api = "https://api.github.com/repos/"
local web_raw = "https://raw.githubusercontent.com/"
local web_req = {
  headers = "Accept: application/vnd.github.v3+json"
}


function fetch_content(target, prefix, filter, entries, api)
  for k, e in pairs(entries) do
    if e["path"]:match("^"..prefix) then
      local ext = e["path"]:match("%.%w*$")
      if ext and filter:match("/".. ext:sub(2) .. "/") then
        local dif = e["path"]:gsub(prefix, ""):match(".*/")
        local fil = e["path"]:match("[%w_%.]*$")
        local dir = target .. (dif and dif or "") 
        if not os.isdir(dir) then os.mkdir(dir) end
        print("fetching\t" .. e["path"])
        local result = http.download(api .. e["path"], dir..fil)
        if result ~= "OK" then
          print("http error " .. result)
          return
        end
      end
    end
  end 
end


function sync_lvgl()
  local lv_api = web_api .. "lvgl/lvgl/git/trees/HEAD?recursive=1"
  local lv_raw = web_raw .. "lvgl/lvgl/master/"
  local lv_res, err = http.get(lv_api, web_req)
  if err == "OK" then
    print("\nfetching lvgl master tree : " .. err)
    local lv_rec, err = json.decode(lv_res) 
    fetch_content("lvgl/src/", "src/", "/c/h/", lv_rec["tree"], lv_raw)
    http.download(lv_raw .. "lvgl.h", "lvgl/lvgl.h") 
  end
  os.copyfile("patch/lv_types.patch", "lvgl/src/misc/lv_types.h")
end


function sync_sdl()
  local sdl_api = web_api .. "libsdl-org/SDL/git/trees/HEAD?recursive=1"
  local sdl_raw = web_raw .. "libsdl-org/SDL/master/"
  local sdl_res, err = http.get(sdl_api, web_req)
  if err == "OK" then
    print("\nfetching SDL master tree : " .. err)
    local sdl_rec, err = json.decode(sdl_res)
    fetch_content("include/SDL2/", "include/", "/h/", sdl_rec["tree"], sdl_raw)
  end
end


function sync_luajit()
  if not os.isdir("../luajit/src") then
    print("You need patched LuaJIT aside template folder.")
    print("Please enter following commands.")
    print("cd ..")
    print("git clone \"https://github.com/LuaJIT/LuaJIT\" luajit")
    print("cd luajit")
    print("git am ../lv-lua/patch/pushclib.patch")
    print("cd src")
    print("make")
  else
    os.mkdir("lib")
    os.mkdir("include/luajit")
    os.copyfile("../luajit/src/lauxlib.h", "include/luajit/lauxlib.h")
    os.copyfile("../luajit/src/lua.h", "include/luajit/lua.h")
    os.copyfile("../luajit/src/lualib.h", "include/luajit/lualib.h")
    os.copyfile("../luajit/src/libluajit.a", "lib/libluajit.a")
    print("fetching luajit headers and libraries : OK")
  end
end

newaction {
  trigger = "sync",
  description = "sync external dependencies",
  onStart = function()
    sync_luajit()
    sync_lvgl()
    sync_sdl()
  end,
}

newaction {
  trigger = "crop",
  description = "remove third-party files",
  onStart = function()
    os.rmdir("include")
    os.rmdir("lvgl")
    os.rmdir("lib")
  end, 
}
