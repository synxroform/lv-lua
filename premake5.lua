require "premake5_sync"
require "premake5_bind"

workspace "microtest"
  configurations { "Release", "Debug"}
  location "build"


filter "language:C"
  includedirs{".", "include"}
  libdirs {"lib"}
  buildoptions {"-Wfatal-errors"}
  filter "configurations:Debug"
    symbols "On"
    buildoptions {"-ggdb3"}
  

project "lvgl"
  kind "StaticLib"
  language "C"
  files {"lvgl/src/**.c", "lvgl/src/**.h"}


project "main"
  kind "ConsoleApp"
  language "C"
  files {"*.c", "*.h"}
  links {"lvgl", "SDL2", "luajit"}
  defines {"USE_SDL", "LV_CONF_INCLUDE_SIMPLE"}
  targetdir "program"
  targetname "main"
  filter "configurations:Debug"
    targetname "main_debug"
