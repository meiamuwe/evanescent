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
private import evanescent.apps.sudoku.solver.SatTransformation;
private import evanescent.apps.sudoku.solver.SudokuSolver;

private import tango.io.model.IConduit : InputStream;
private import tango.io.stream.FileStream;
private import tango.core.Exception;
private import tango.io.Stdout; 

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
	Stdout.format("================== Evanescent SUDOKU-Solver Version 0.1 =====================").newline();
	Stdout.format("=============================================================================").newline();
	Stdout.newline();

	InputStream inStream = (new FileInput(args[1])).input();
	Stdout.formatln("Reading SUDOKU problem from file: {}", args[1] );

	SudokuParser problemParser = new SudokuParser();
	Puzzle problem = problemParser.parse(inStream); 

	Stdout.formatln("SUDOKU problem to solve is:\n{}", problem.toString());


	if (!problem.valid)
	{
		Stdout.formatln("The puzzle is not a valid SUDOKU problem; it does not satisfy the SUDOKU rules.").newline;
		return 0; 
	}
	
	StopWatch* watch = new StopWatch();
	watch.start();

	SudokuSolver sudokuSolver = new SudokuSolver();
	Puzzle solution; 

	bool isSolvable = sudokuSolver.solve(problem, solution);
	double cpu_time_s = watch.stop() ;

	if (isSolvable)
	{
		Stdout.formatln("The SUDOKU puzzle is solvable.").newline;
		Stdout.formatln("Found the following solution for the puzzle:\n");
		Stdout.formatln("{}", solution.toString());

	} else {
		Stdout.formatln("The SUDOKU puzzle does not have any solution.");
	}

	Stdout.formatln("Time to solve the puzzle: {,14:f6} sec.", cpu_time_s).newline;

	problemParser = null;
	sudokuSolver = null;
	watch = null;

	return 1; 
}


