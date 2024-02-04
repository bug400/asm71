#!/bin/bash
if [ "`dirname $0`" != "." ] ; then
   echo "script must be called from its subdirectory"
   exit 1
fi
export version=`cat ../version.txt`
if [ -z "${version}" ] ; then
   echo "missing or empty version.txt file"
   exit 1
fi
rm -rf asm71.dst/*
#
# Intel build
#
export Platform=x86_64
rm -rf ../cmake-tmp
mkdir ../cmake-tmp
pushd ../cmake-tmp > /dev/null
cmake .. 
make
cp asm71 ../macos/asm71.intel
popd > /dev/null
#
# Arm build
#
export Platform=aarch64
rm -rf ../cmake-tmp
mkdir ../cmake-tmp
pushd ../cmake-tmp > /dev/null
cmake .. 
make
cp asm71 ../macos/asm71.arm
make DESTDIR=../macos/asm71.dst install
popd > /dev/null
#
# create universal binary
#
lipo -create -output asm71 asm71.arm asm71.intel
strip asm71
cp asm71 asm71.dst/usr/local/bin
#
# test universal binary
#
pushd ../cmake-tmp > /dev/null
cp ../macos/asm71 .
make test
make clean
popd > /dev/null
#
# build package
#
rm -rf asm71.resources
mkdir asm71.resources
cp ../LICENSE asm71.resources
echo "ASM71 ${version}"  > asm71.resources/welcome.txt
echo "" >> asm71.resources/welcome.txt
echo "This package installs the ASM71 in the location /usr/local." >> asm71.resources/welcome.txt
echo "Please uninstall any previously installed version first." >> asm71.resources/welcome.txt
echo "ASM71 ${version} was installed on your system"  > asm71.resources/conclusion.txt
echo "" >> asm71.resources/conclusion.txt
echo "To uninstall the ASM71 do the following:" >> asm71.resources/conclusion.txt
echo "" >> asm71.resources/conclusion.txt
echo "Run the script create_asm71_removescript.sh to create an uninstall script:" >> asm71.resources/conclusion.txt
echo "bash /usr/local/share/asm71/create_asm71_removescript.sh > uninstall.sh" >> asm71.resources/conclusion.txt
echo "" >> asm71.resources/conclusion.txt
echo "Run the script uninstall.sh as administrator:" >> asm71.resources/conclusion.txt
echo "sudo bash ./uninstall.sh" >> asm71.resources/conclusion.txt
echo "" >> asm71.resources/conclusion.txt
echo "Due to security reasons each delete operation requires confirmation." >> asm71.resources/conclusion.txt
cp create_asm71_removescript.sh asm71.dst/usr/local/share/asm71
rm -rf build_products
mkdir build_products
pkgbuild --identifier org.bug400.asm71 --version=$version --install-location="/" --root asm71.dst --component-plist asm71.plist build_products/asm71.pkg 
productbuild --distribution asm71.xml --package-path=build_products/ --resources=asm71.resources asm71.pkg
rm build_products/asm71.pkg
rm -rf asm71.dst/*
rm -rf ../cmake-tmp
rm -f asm71 asm71.intel asm71.arm
