@echo off
echo -------------------------------------------------
echo -- Running unit test for Deescover ...
echo -------------------------------------------------

set PATH_TO_JAKE=\dmd\bin
set PATH_TO_D_COMPILER_BIN_DIR=\dmd\bin

cd src

%PATH_TO_JAKE%\jake -op -debug -unittest -ofrunUnitTests evanescent\deescover\test\runUnitTests.d 
%PATH_TO_D_COMPILER_BIN_DIR%\dmd @rsp

runUnitTests.exe

del runUnitTests.exe
del *.map
del *.obj
del rsp
cd ..
