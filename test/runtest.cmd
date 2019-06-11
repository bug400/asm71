@ECHO OFF
REM
REM Ctest test driver for ASM71
REM It uses the find command supplied by the vi editor
REM
REM Parameters:
REM 1: name of test file
REM 2: path to executables
REM
set ASM71REGRESSIONTEST=1
set PATH=%~2;%PATH%
set testfile=%~1
pushd %testfile%
if exist %testfile%.out del /F %testfile%.out
call %testfile%.cmd > %testfile%.out
diff %testfile%.out reference\%testfile%.out
set ret=%errorlevel%
if exist %testfile%.out del /F %testfile%.out
popd
exit /B %ret%
