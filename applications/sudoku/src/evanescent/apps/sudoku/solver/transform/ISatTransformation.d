/**
 * <hr />
 * $(B Evanescent Applications: ) SUDOKU 
 * 
 * $(BR)
 * 
 * Authors: Uwe Keller
 * License: MIT
 * 
 * Version: 0.1.1 - April 2010
 */
 
module evanescent.apps.sudoku.solver.transform.ISatTransformation;

private import evanescent.deescover.core.Solver;
private import evanescent.apps.sudoku.core.Puzzle;
private import evanescent.apps.sudoku.solver.transform.PropositionalSignature;

/**
 * Common interface for various transformations of
 * puzzles to SAT problems.
 * 
 * A sat transformation takes a puzzle and converts it
 * into a propositional theory (that is adequate for the
 * purpose of the computation to be performed later on by
 * the SAT solver)
 * 
 * The symbols to be used for representing the puzzle
 * are managed by a propositional signature. The signature
 * must be set before the transformation is invoked.
 * 
 * The propositional theory is directly stored in a
 * SAT solver that has been set as the target solver before
 * the transformation is started.
 * 
 * Authors: Uwe Keller
 */
interface ISatTransformation {
	
	/**
	 * Sets the target solver in which to store the
	 * generated propositional theory
	 * 
	 * Params:
	 *     satSolver = the target solver working on the generated problem later on
	 */
	public void setTargetSolver(Solver satSolver);
	
	/**
	 * Sets the propositional signature to be used during the transformation
	 * Params:
	 * 	   signature = the propositional symbols to be used for representing the
	 * 	   properties of the puzzle formally
	 */
	public void setSignature(PropositionalSignature signature);
	
	/**
	 * Transform a puzzle into a propositional theory
	 * Params:
	 *     p = the puzzle to be transformed to a SAT problem
	 */
	public void transform(Puzzle p);
	
	/**
	 * Reconstructs a puzzle from the model represented in the 
	 * SAT solver (if any). If the solver did not yet compute
	 * a model, the result will be a puzzle object but typically
	 * not represent a solution to the puzzle
	 * 
	 * Returns:
	 * 	the puzzle that corresponds to the propositional model
	 *  found by the SAT solver (if any).
	 */
	public Puzzle solution(); 
	
	
} 