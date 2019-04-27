#!/bin/bash
if [ "`dirname $0`" != "." ] ; then
   echo "script must be called from its subdirectory"
   exit 1
fi
pushd .. > /dev/null
rm -f ../asm71_*.deb
rm -f ../asm71_*.changes
dpkg-buildpackage -b -tc -uc
mv ../asm71_*.deb linux
mv ../asm71_*.changes linux
rm -f ../asm71-dbgsym*.deb
rm -f ../asm71_*buldinfo
popd > /dev/null
