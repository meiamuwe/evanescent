@echo off
echo -----------------------------------------------------------------
echo -- Building Evanescent SUDOKU Solver ...
echo -----------------------------------------------------------------

set PATH_TO_JAKE=\dmd\bin
set PATH_TO_D_COMPILER_BIN_DIR=\dmd\bin

cd src

%PATH_TO_JAKE%\jake -op -release -ofsudoku-solver -version=Tango -I..\..\..\deescover\src\ -Isrc\ evanescent\apps\sudoku\core\CommandLineInterface.d
%PATH_TO_D_COMPILER_BIN_DIR%\dmd @rsp

move sudoku-solver.exe ..\bin
del *.map
del *.obj
del rsp
cd ..

echo -- ... done!
echo -----------------------------------------------------------------
echo -- Please find the Evanescent SUDOKU Solver executable in bin\
echo -----------------------------------------------------------------