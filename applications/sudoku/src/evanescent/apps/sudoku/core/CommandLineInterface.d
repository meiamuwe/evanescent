/**
 * <hr />
 * $(B Evanescent Applications: ) SUDOKU 
 * 
 * $(BR)
 * 
 * Authors: Uwe Keller
 * License: MIT
 * 
 * Version: 0.1 - April 2009, initial release
 */

module evanescent.apps.sudoku.core.CommandLineInterface;

private import evanescent.apps.sudoku.core.Puzzle; 
private import evanescent.apps.sudoku.parser.Parser;
private import evanescent.apps.sudoku.solver.SudokuSolver;

private import tango.io.model.IConduit : InputStream;
private import tango.io.device.File;
private import tango.core.Exception;
private import tango.io.Stdout; 

import tango.stdc.posix.sys.types;
private import tango.time.StopWatch;



protected void printUsage(char[][] args){
	Stdout.formatln(" USAGE: {} <sudoku-puzzle-file> \n\n  where input file must be in plain SUDOKU format.\n", args[0]);
	Stdout.newline;
}


public int main(char[][] args)
{

	if (args.length != 2)
	{
		printUsage(args);
		return 0;
	}


	Stdout.newline().newline();
	Stdout.format("=============================================================================").newline();
	Stdout.format("================== Evanescent SUDOKU-Solver Version 0.1.1 ===================").newline();
	Stdout.format("=============================================================================").newline();
	Stdout.newline();

	InputStream inStream = (new File(args[1])).input();
	Stdout.formatln("Reading SUDOKU problem from file: {}", args[1] );

	SudokuParser problemParser = new SudokuParser();
	Puzzle problem = problemParser.parse(inStream); 

	Stdout.formatln("SUDOKU problem to solve is:\n{}", problem.toString());


	if (!problem.valid())
	{
		Stdout.formatln("The puzzle is not a valid SUDOKU problem; it does not satisfy the SUDOKU rules.").newline;
		return 0; 
	}
	
	StopWatch* watch = new StopWatch();
	watch.start();

	SudokuSolver sudokuSolver = new SudokuSolver(problem);
	bool isSolvable = sudokuSolver.foundSolution();

	double cpu_time_s = watch.stop();

	Stdout.formatln("Time to solve the puzzle: {,14:f6} sec.", cpu_time_s).newline;

	if (isSolvable)
	{
		Stdout.formatln("The SUDOKU puzzle is solvable.").newline;
		Stdout.formatln("Found the following solution for the puzzle:\n");
		Stdout.formatln("{}", sudokuSolver.solution().toString());

	} else {
		Stdout.formatln("The SUDOKU puzzle does not have any solution.");
	}

	// Now check if the puzzle has more solutions (or is uniquely solvable). 

	if (sudokuSolver.foundSolution())
	{
		Stdout.formatln("The puzzle is NOT UNIQUELY SOLVABLE!").newline;
		Stdout.formatln("The following additional solution has been found: ").newline;
		
		Stdout.formatln("{}", sudokuSolver.solution().toString());
		
	} else {
		Stdout.formatln("The found solution is the ONLY SOLUTION to the input puzzle. ");
	}
	
	problemParser = null;
	sudokuSolver = null;
	watch = null;

	return 1; 
}


