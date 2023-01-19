GENie - Project generator tool
==============================

What is it?
-----------

**GENie** (pronounced as Jenny) is project generator tool. It automagically
generates project from Lua script, making applying the same settings for
multiple projects easy.

Note: This is the XYZ Reality's forked and customized version of GENie, added
Linux on ARM architecture support to be able to build projects on nVidia Orin board.
For the original repo readme please go to: https://github.com/XYZReality/GENie/Original_README.md

Building
--------
**Important Note:** You normally don't need to build this tool as it is only for internal development, used in some repos
to generate multi-platform project files (e.g. for bgfx, bx, bimg). The output binaries of this tool as well as 
the project files for all desired platforms are alreay generated and added to our corresponding customized forked repos.

But in case you need to rebuild this tool, please follow the instructions here:

**Windows:**
```
1- Clone the repo to some folder
2- Open the visual studio solution file from GENie/scripts/genie.sln
3- Build
```
Running this tool under Windows doesn't give you too much since it is mainly targeted for Linux.
**Linux:**
```
1- Clone the repo to some folder
2- $ cd GENie
3- $ make
```
Based on the CPU architecture of the machine you are running, it will generate the binaries in either GENie/bin/linux or
GENie/bin/linux-arm accordingly.

