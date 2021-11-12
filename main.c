#define SDL_MAIN_HANDLED

#ifdef _WIN32
  #include <windows.h>
#else
  #include <unistd.h>
#endif

#include <SDL2/SDL.h>
#include <stdio.h>
#include <string.h>
#include <lvgl/lvgl.h>
#include <luajit/lua.h>
#include <luajit/lauxlib.h>
#include <luajit/lualib.h>

void  driver_init();
int   push_api(lua_State*); 


static void get_main_script_path(char *buf, int sz) 
{
#if _WIN32
  int len = GetModuleFileName(NULL, buf, sz - 1);
#else
  char path[512];
  sprintf(path, "/proc/%d/exe", getpid());
  int len = readlink(path, buf, sz - 1);
#endif  
  memcpy(&buf[len-3], "lua\0", 4);
  for (int n = 0; buf[n]; n++) {
    if (buf[n] == '\\') buf[n] = '/';
  }
}


int load_main_lua(lua_State *ls) 
{
  luaL_openlibs(ls);
  char msp[2048] = {0};
  get_main_script_path(msp, sizeof(msp));
  
  // environment
  lua_createtable(ls, 0, 1);
  lua_pushstring(ls, "MODPATH");
  lua_pushstring(ls, msp);
  lua_settable(ls, -3);
  lua_setglobal(ls, "main");
  
  if (push_api(ls)) {   
    printf("error: failed to push api.\n");
    lua_error(ls);
    return 1;
  }
  if (luaL_loadfilex(ls, msp, "t") || lua_pcall(ls, 0, 0, 0)) { 
    printf("error: %s\n", lua_tostring(ls, -1));
    return 1;
  };
  return 0;
}


int main(int argc, char** argv) 
{
  lua_State *ls = luaL_newstate();
  driver_init();

  for(char err = load_main_lua(ls); !err ;) {
    lv_timer_handler();
    SDL_Delay(5);
  }
  
  lua_close(ls);
  return 0;
}

