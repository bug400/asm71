#
# build file for asm71
#
project(asm71)
cmake_minimum_required (VERSION 2.8.4)
set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake_modules")
enable_language(Pascal)
#
# set build type = Release
#
set(CMAKE_BUILD_TYPE "Release")
#
# Install Prefix
#
if(UNIX)
  if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(CMAKE_INSTALL_PREFIX "/usr")
  else()
    set(CMAKE_INSTALL_PREFIX "/usr/local")
  endif()
endif(UNIX)
#
# Windows cross compiling for 64 bit
#
if(WIN32)
  if ($ENV{Platform} STREQUAL "x64")
    set(CMAKE_Pascal_FLAGS "${CMAKE_Pascal_FLAGS} -Px86_64")
  endif()
endif(WIN32)
#
# buld emu7470
#
add_executable( "asm71" "src/asm71.pas")
#
# install executables
#
IF(UNIX)
   set(BINPATH "bin")
   set(DOCPATH "share/doc/asm71")
   set(DATAPATH "share/asm71")
   set(MANPATH "share/man")
ENDIF(UNIX)
IF(WIN32)
   set(BINPATH ".")
   set(DOCPATH "doc")
ENDIF(WIN32)
install(TARGETS "asm71" DESTINATION ${BINPATH})
#
# install documentation
#
install(FILES doc/asm71.html doc/GPL-2 DESTINATION ${DOCPATH} )
#
# install man page
#
if(UNIX)
install(FILES man/asm71.1 DESTINATION ${MANPATH}/man1)
endif(UNIX)
#
# install example
#
if(UNIX)
install(FILES examples/bsp.asm DESTINATION ${DATAPATH})
endif(UNIX)
