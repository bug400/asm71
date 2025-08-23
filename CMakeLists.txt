#
# build file for asm71
#
cmake_minimum_required (VERSION 3.10.0)
project(asm71)
set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake_modules")
enable_language(Pascal)
enable_testing()
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
# macOS cross compiling Intel or M1
#
if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
  if ($ENV{Platform} STREQUAL "aarch64")
    set(CMAKE_Pascal_FLAGS "${CMAKE_Pascal_FLAGS} -Paarch64")
  endif()
  if ($ENV{Platform} STREQUAL "x86_64")
    set(CMAKE_Pascal_FLAGS "${CMAKE_Pascal_FLAGS} -Px86_64")
  endif()
endif()
#
# buld asm71
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

# tests
#
if(WIN32)
    SET(TESTDRIVER "runtest.cmd")
endif(WIN32)
if (UNIX)
    SET(TESTDRIVER "runtest.sh")
endif(UNIX)
add_test(NAME basic WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/test COMMAND  "${CMAKE_SOURCE_DIR}/test/${TESTDRIVER}" "basic" "${CMAKE_CURRENT_BINARY_DIR}")
#add_test(NAME jpcf05 WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/test COMMAND  "${CMAKE_SOURCE_DIR}/test/${TESTDRIVER}" "jpcf05" "${CMAKE_CURRENT_BINARY_DIR}")

