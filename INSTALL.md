ASM71 Installation instructions
===============================

Index
-----

* [Installation of the precompiled binaries](#installation-of-the-precompiled-binaries)
* [Build from scratch](#build-from-scratch)


Installation of the precompiled binaries
----------------------------------------

LINUX:

The releases section provides installers (.deb files) for Debian Linux and compatible distributions. See
the release comments, which Debian version is currently supported. To install the .deb file, issue the following command as root in the directory containing the installer file:

     apt install ./asm71_X.Y.Z_<architecture>.deb

**Note:** This command installs the software package from a downloaded file, not from a repository. To obtain a new version of the software, you must download the corresponding deb package and install it using the command above. The previous program version will then be overwritten.

Windows:

There is an MSI installer file to safely install ASM71 on Windows 10/11. There is no 32bit version any more. The installer only allows an installation for the current user and modifies the PATH environment variable. The package can be removed in the "Apps and Features" section in the Windows Settings. The changes to the PATH variable are then reset.

Since there is no longer a Start Menu entry for ASM71, it is recommended that you create a link to the file


     C:\Users\<your username>\AppData\Local\Programs\asm71\doc\readme.html

on the desktop in order to access the documentation.

**WARNING**

Version 2.1.1 had to switch to the Microsoft msiexec installer to ensure that ASM71 can continue to be installed securely. This means that an automatic upgrade from version 2.1.0 and earlier is not possible. You must therefore manually uninstall all existing installations (both system-wide and local) before version 2.1.1 can be installed.


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
