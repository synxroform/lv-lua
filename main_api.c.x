#include <stdio.h>
#include <stdlib.h>
#include <lvgl/lvgl.h>
#include <luajit/lua.h>
#include <luajit/lauxlib.h>
#include <luajit/lualib.h>

static lv_style_t* lx_new_style() {
  lv_style_t* s = malloc(sizeof(lv_style_t));
  lv_style_init(s);
  return s;
}

static void lx_free_style(lv_style_t *st) {
  lv_style_reset(st);
  free(st);
}

static lv_anim_t* lx_new_anim() {
  lv_anim_t* a = malloc(sizeof(lv_anim_t));
  lv_anim_init(a);
  return a;
}

static struct _lv_event_dsc_t* lx_obj_add_event_cb(lv_obj_t* obj, lv_event_cb_t cb, lv_event_code_t code) {
  return lv_obj_add_event_cb(obj, cb, code, NULL);
}

static clib_functions api[] = {
{ &lx_obj_add_event_cb, "_lv_event_dsc_t* add_event_cb(lv_obj_t*, lv_event_cb_t, lv_event_code_t);" },
{ &lx_new_style, "lv_style_t* __lx_new_style();" },
{ &lx_free_style, "void __lx_free_style(lv_style_t*);" },
{ &lx_new_anim, "lv_anim_t* __lx_new_anim();" },
{ &free, "void __lx_free_anim(void*);" },

DO_DECL

{ NULL, NULL}
};


static const char* cdef = \
"typedef void lv_style_t;"
"typedef void lv_anim_t;"

DO_CDEF



static void push_gc_cdata(lua_State *ls, const char* ctor, const char* dtor)
{
  lua_getglobal(ls, "lv");
  lua_getglobal(ls, "ffi");
  lua_getfield(ls, -1, "gc");
  lua_getfield(ls, -3, ctor);
  if(lua_pcall(ls, 0, 1, 0)) lua_error(ls); // cdata* lv.ctor()
  lua_getfield(ls, -4, dtor);
  if(lua_pcall(ls, 2, 1, 0)) lua_error(ls); // cdata* ffi.gc(cdata*, lv.dtor)
}


static int new_style(lua_State *ls) {
  push_gc_cdata(ls, "__lx_new_style", "__lx_free_style");
  return 1;
}

static int new_anim(lua_State *ls) {
  push_gc_cdata(ls, "__lx_new_anim", "__lx_free_anim");
  return 1;
}


// constructors for garbage collected objects
// it's not advised to gc lv_obj_t* because
// each widget belong to some parent
//
static void push_constructors(lua_State *ls) 
{
  lua_createtable(ls, 0, 1);  
  lua_pushcfunction(ls, new_style);
  lua_setfield(ls, -2, "style");
  lua_pushcfunction(ls, new_anim);
  lua_setfield(ls, -2, "anim");
  lua_setglobal(ls, "new");
}


int push_api(lua_State *ls) 
{
  lua_getglobal(ls, "require");
  lua_pushstring(ls, "ffi");
  if (lua_pcall(ls, 1, 1, 0)) return 1;
  lua_setglobal(ls, "ffi");
  if (lua_fficdef(ls, cdef) || lua_push_ffi_lib(ls, api)) {
    if (lua_isstring(ls, -1)) {
      printf("%s \n", lua_tostring(ls, -1));
    }
    return 1;
  }
  lua_setglobal(ls, "lv");
  push_constructors(ls);
  
  return 0;
}

