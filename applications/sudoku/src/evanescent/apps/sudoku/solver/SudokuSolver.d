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


module evanescent.apps.sudoku.solver.SudokuSolver;


private import evanescent.deescover.core.SolverTypes; 
private import evanescent.deescover.core.Solver;
private import evanescent.deescover.core.clause.Clause;
private import evanescent.deescover.util.Vec;


private import evanescent.apps.sudoku.core.Puzzle; 
private import evanescent.apps.sudoku.solver.SatTransformation; 


private import tango.io.Stdout; 

/**
 * A solver for SUDOKU puzzles working in the following phases:
 * 
 * 1. Tranform the puzzle into an equivalent propositional SAT problem
 * 
 * 2. Use a SAT solver to compute a solution to the puzzle or
 * detect that the puzzle can not be solved
 * 
 * 3. If the SAT solver found a propositional model, convert
 * the model into the corresponing solution to the SUDOKU puzzle.
 * 
 * The generated SAT problem is equivalent in the following sense: 
 * 
 * There is bijection $(I sudoku2sat) between SUDOKU puzzles P' 
 * without empty cells that extend 
 * the given input puzzle P and interpretations I of the correpsonding
 * propositional problem SAT(P) such that
 * 
 * 		I is a model of SAT(P) iff. 
 * 		P' := inverse($(I sudoku2sat))(I) is a solution to the SUDOKU puzzle P  
 *   
 * 
 * Authors: Uwe Keller
 */
public class SudokuSolver {
	
	/**
	 * Solve a SUDOKU puzzle by instantiation all empty cells. 
	 * 
	 * More specifically, the solver fills in all
	 * empty cells of the puzzle such that all 
	 * SUDOKU rules are satisfied. 
	 * 
	 * If the puzzle is solvable the method returns true and
	 * in the out parameter $(I solution) an extension of ($I puzzle)
	 * that has no empty cells left and satisfies all SUDOKU rules.
	 * If the  puzzle is unsolvable the method returns false. In this
	 * case the out parameter $(I solution) is set to null. 
	 * 
	 * Params:
	 *     puzzle = the SUDOKU puzzle to solve
	 *     solution = the filled in puzzle (out parameter) 
	 *     
	 * Returns: true iff puzzle is solvable. 
	 * 
	 */
	public bool solve(in Puzzle puzzle, out Puzzle solution)
	in {
		assert (puzzle.valid()); 
	}
	out(result) {
		if(result == true) { 
			assert ( solution.solutionOf(puzzle) );
		}
	}
	body 
	{
		bool isSolvable = false; 
		
		solution = null;
	
		if (puzzle.solutionOf(puzzle))
		{ //trivial case: no need to transform to SAT and invoke the solver
			solution = puzzle; 
			return true;
		}
		
		Solver satSolver = new Solver();
		SatTransformation sudokuTransformer = new SatTransformation(satSolver);
		
		sudokuTransformer.transform(puzzle); 

		if (satSolver.simplify() == true)
		{
			isSolvable = satSolver.solve();
			if (isSolvable)
			{
				solution = sudokuTransformer.solution(); 
			} 

		} else {
			// the corresponding SAT problem is unsatisfiable
			// already in the simplification phase (no actual search
			// has been performed)
			isSolvable = false; 
		}	
		
		return isSolvable; 
	}
}
