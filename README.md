# lv-lua
Quick prototyping LuaJIT environment for LVGL.

## installation
```
premake5 sync
premake5 bind
premake5 gmake2
cd build
make -j4
../program/main.exe
```

## sync

This command will fetch all necessary files to build your project. It doesn't 
use submodule concept, clean and minimal source will be placed in **lvgl** folder. 
SDL and LuaJIT headers goes into **include** directory, you shouldn't use this 
directory to store your own headers. Automatically created files and directories 
will not be tracked by version control system, in order to change this behaviour 
edit **.gitignore** file.

## bind

This command will generate API bindings for LuaJIT. It allows you to customize environment 
for your personal needs. You can easily change exposed content by editing **premake5_bind.lua** 
file. By default all objects generated on the C side appears to Lua as a black boxes. Creation 
of C types on the Lua side should be handled by dedicated constructors and destructors in order 
to avoid memory leaks. If you want to add new garbage collected types just place them in **main_api.c.x**.

## cleanup
```
premake5 crop
```
## notes
I'm using **msys2** and **gcc** as a development environment. All build dependencies can be easily 
installed using **pacman**. Beside standard tools, you'll need **premake5** and **SDL** library, 
make sure this library is in sync with latest headers from github. 
```


