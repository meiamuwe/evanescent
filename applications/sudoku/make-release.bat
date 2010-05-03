@echo off
echo -----------------------------------------------------------------
echo -- Building Evanescent SUDOKU Solver ...
echo -----------------------------------------------------------------

set PATH_TO_JAKE=\dmd-tango\bin
set PATH_TO_D_COMPILER_BIN_DIR=\dmd-tango\bin

cd src

%PATH_TO_JAKE%\jake -op -O -release -inline -ofdeescover-sudoku -version=Tango -I..\..\..\deescover\src\ -Isrc\ evanescent\apps\sudoku\core\CommandLineInterface.d
%PATH_TO_D_COMPILER_BIN_DIR%\dmd @rsp

move deescover-sudoku.exe ..\bin
del *.map
del *.obj
del rsp
cd ..

echo -- ... done!
echo -----------------------------------------------------------------
echo -- Please find the Evanescent SUDOKU Solver executable in bin\
echo -----------------------------------------------------------------