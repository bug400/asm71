#!/bin/bash
#
# Ctest test driver for ASM71
#
# Parameters:
# 1: name of test file
# 2: path to executables
#
if test -z "${1}" ; then
    testfile="regression"
else
    testfile=$1
fi
if test ! -z "${2}" ; then
    export PATH=$2:$PATH
fi
export ASM71REGRESSIONTEST=1
cd ${testfile}
rm -f ${testfile}.out
./${testfile}.sh > ${testfile}.out
diff ${testfile}.out reference/${testfile}.out
ret=$?
rm -f ${testfile}.out
exit $ret
