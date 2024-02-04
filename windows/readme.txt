Build the Windows version of ASM71

Build requirements:

cmake, Visual Studio 2022 build tools, Free Pascal compiler 3.2.2, nsis 3.0.9
installation must be manually enhanced with the strlen 8192 special build,  then EnvVar plugin, 
the multi user extension (https://github.com/Drizin/NsisMultiUser - but without the dlls in the Plugins 
directory), StdUtils v1.14 (https://github.com/lordmulder/stdutils/releases) and the UAC plugin 
(https://nsis.sourceforge.io/UAC_plug-in)

Build:
run build_asm71.cmd compiles ASM71 and creates a windows installer for
the current VS build tool environment.

Note: you must set the environment variable NSISDIR which points to the root directory of the install
system
