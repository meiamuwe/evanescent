@echo off
echo -------------------------------------------------
echo -- Building Deescover ...
echo -------------------------------------------------

set PATH_TO_JAKE=\dmd-tango\bin
set PATH_TO_D_COMPILER_BIN_DIR=\dmd-tango\bin

cd src

%PATH_TO_JAKE%\jake -op -O -release -inline -ofdeescover_release evanescent\deescover\core\Deescover.d
%PATH_TO_D_COMPILER_BIN_DIR%\dmd @rsp

move deescover_release.exe ..\bin
del *.map
del *.obj
del rsp
cd ..

echo -- ... done!
echo -------------------------------------------------
echo -- Please find the Deescover executable in bin\
echo -------------------------------------------------