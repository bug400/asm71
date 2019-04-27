ASM71 Installation instructions
===============================

Index
-----

* [Installation of the precompiled binaries](#installation-of-the-precompiled-binaries)
* [Build from scratch](#build-from-scratch)


Installation of the precompiled binaries
----------------------------------------

LINUX:

There are DEBIAN packages available for download (32-bit and 64-bit).
Install the package as root.

     dpkg -i <package-file-name>


Windows:

There are installer exe file to safely install ASM71. Download 
the appropriate 32 or 64 bit version of the installer file follow the
instructions below.

* Uninstall any previous installed version of ASM71 before installing
a new version.
* A 32 bit version of ASM71 will not install on a 64 bit windows
* you may choose a system-wide installation or an installation only for
the current user. A system-wide installation requires administrator privileges.
* You may choose to have the installer modify the PATH variable. This is not needed if you call ASM71 from the "ASM71 prompt" in the start menu.
* The uninstaller fails if issued from "Apps and Features" in Windows 10. 
Uninstall ASM71 from the control panel instead.


macOS:

There is a package that installs the package under /usr/local.

Note: you get a message that the package cannot be opened because it is from
an unidentified developer. Click on the "?" button in the message window to
learn how to proceed.

To uninstall ASM71 run the script create_asm71_removescript.sh to 
create an uninstall script:

     bash /usr/local/share/asm71/create_asm71_removescript.sh > uninstall.sh

The run the script uninstall.sh as administrator:

     sudo bash ./uninstall.sh

Due to security reasons each delete operation requires confirmation.



Build from scratch
------------------

ASM71 was migrated to the CMake build system. The Free Pascal configuration files for CMake were gratefully taken from the [Hedgewars project](https://github.com/hedgewars/hw).

Download the ASM71 source package and follow the instruction in the
build directories:

* linux: Linux (Debian package tools and Free Pascal compiler)
* macos: macOS (XCode command line tools and Free Pascal compiler)
* windows (MSVC 2017, Free Pascal Compiler and nsis 3.0 package builder)
