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

module evanescent.apps.sudoku.runUnitTests; 

import tango.io.Stdout;

/**
 * Add here all modules for which unit tests should be run.
 * For at least all mentioned modules, the unit tests 
 * will be run. For all indirectly references ones, 
 * this is the case too.
 */

import evanescent.apps.sudoku.parser.Parser;

public int main(char[][] args){
	Stdout("\n\nFinished running all unit tests SUCCESSFULLY!").newline.newline; 
	return 0;
}


