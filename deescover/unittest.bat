@echo off
echo -------------------------------------------------
echo -- Running unit test for Deescover ...
echo -------------------------------------------------

set PATH_TO_JAKE=\dmd-tango\bin
set PATH_TO_D_COMPILER_BIN_DIR=\dmd-tango\bin

cd src

%PATH_TO_JAKE%\jake -op -debug -unittest -ofrunUnitTests evanescent\deescover\test\runUnitTests.d 
%PATH_TO_D_COMPILER_BIN_DIR%\dmd @rsp

move runUnitTests.exe ..\bin

del *.map
del *.obj
del rsp
cd ..

bin\runUnitTests.exe

del bin\runUnitTests.exe

