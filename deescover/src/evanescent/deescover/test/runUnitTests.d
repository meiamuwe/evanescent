/**
 * <hr />
 * $(B Deescover -) 
 * A modern state-of-the-art SAT solver written in D.
 * 
 * $(P)
 * $(I Deescover is based on the MiniSat-2 (see $(LINK http://minisat.se/)) 
 * solver written in C++ by Niklas Een and Niklas Sorensson) $(BR) 
 * <hr />
 * 
 * A module that can be used for running all unit tests
 * in the project 
 *
 * Authors: Uwe Keller,
 * License: MIT
 * 
 * Version: 0.1 - April 2009, initial release 
 */
module evanescent.deescover.test.runUnitTests; 

import tango.io.Stdout;

/**
 * Add here all modules for which unit tests should be run.
 * For at least all mentioned modules, the unit tests 
 * will be run. For all indirectly references ones, 
 * this is the case too.
 */

import evanescent.deescover.util.Sort;
import evanescent.deescover.util.Vec;
import evanescent.deescover.util.Heap;
import evanescent.deescover.core.clause.Clause;
import evanescent.deescover.core.SolverTypes;
import evanescent.deescover.core.Solver;

import evanescent.deescover.parser.dimacs.DimacsParser;
import evanescent.deescover.parser.dimacs.AbstractDimacsHandler;

import evanescent.deescover.util.Sort;

public int main(char[][] args){
	Stdout("\n\nFinished running all unit tests SUCCESSFULLY!").newline.newline; 
	return 0;
}


