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


module evanescent.apps.sudoku.solver.SudokuSolver;


private import evanescent.deescover.core.SolverTypes; 
private import evanescent.deescover.core.Solver;
private import evanescent.deescover.core.clause.Clause;
private import evanescent.deescover.util.Vec;


private import evanescent.apps.sudoku.core.Puzzle; 
private import evanescent.apps.sudoku.solver.transform.ISatTransformation;
private import evanescent.apps.sudoku.solver.transform.SatTransformation;
private import evanescent.apps.sudoku.solver.transform.SolutionNotExtendingPuzzleRequirement;
private import evanescent.apps.sudoku.solver.transform.PropositionalSignature;

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
 * The solver can be used to enumerate all solutions to a given SUDOKU puzzles
 * using multiple calls to the method foundSolution()
 * Each call to this method is guarantueed to compute a new solution, 
 * or report that no more solutions can be found and the enumeration stops.
 * 
 * Hence, the solver keeps internal state representing previously 
 * found solutions. 
 * 
 * Authors: Uwe Keller
 */
public class SudokuSolver {
	
	/**
	 * The puzzle to solve
	 */
	private Puzzle puzzle; 
	
	/**
	 * The solution computed previously
	 */
	private Puzzle previousSolution; 
	
	/**
	 * The SAT solver used to solve the puzzle
	 */
	private Solver satSolver; 
	
	/**
	 * The propositional signature used to represent the puzzle
	 */
	private PropositionalSignature problemSignature; 
	
	// ----------------------------------------------
	// Constructors
	// ----------------------------------------------

	public this(Puzzle p)
	in {
		assert (p.valid()); 
	}
	body {
		puzzle = p;
		previousSolution = null;
		

		satSolver = new Solver();
		problemSignature = new PropositionalSignature(puzzle,satSolver);
		
	}
	
	
	
	// ----------------------------------------------
	// Methods
	// ----------------------------------------------

	/**
	 * Solve a SUDOKU puzzle by instantiation all empty cells. 
	 * 
	 * More specifically, the solver fills in all
	 * empty cells of the puzzle such that all 
	 * SUDOKU rules are satisfied. 
	 * 
	 * The computed solution can be retrieved by a call
	 * to $(D_CODE solution() ). 
	 *  
	 * Subsequent calls to the method will compute new solutions
	 * that are different from all previously computed solutions.    
	 *     
	 * Returns: true iff puzzle has another solution that is
	 * different from all previously computed solutions.
	 * 
	 */
	public bool foundSolution()
	out(result) {
		if(result == true) { 
			assert ( previousSolution !is null && previousSolution.solutionOf(puzzle) );
		}
	}
	body
	{
		bool isSolvable = false; 
		
		ISatTransformation sudokuTransformer;
		if (previousSolution is null)
		{
			// We did not yet compute any solution to the puzzle
			
			sudokuTransformer = 
				new SatTransformation(satSolver,problemSignature);
			
			sudokuTransformer.transform(puzzle); 
		}
		else 
		{
		 	
			 
			// Not the first call to find a solution, hence we need to retrieve a
			// novel solution
			
			// We add (to the solver we used before) additional clauses 
			// that require the solver to look for a novel solution
			// i.e. a solution that is different from the (and hence any) 
			// previous solution that we have been found so far
			
			sudokuTransformer = 
				new SolutionNotExtendingPuzzleRequirement(satSolver,problemSignature);
			
			sudokuTransformer.transform(previousSolution); 
		}
		
		if (satSolver.simplify() == true)
		{
			isSolvable = satSolver.solve();
			if (isSolvable)
			{
				previousSolution = sudokuTransformer.solution(); 
			} 

		} else {
			// the corresponding SAT problem is unsatisfiable
			// already in the simplification phase (no actual search
			// has been performed)
			isSolvable = false; 
		}	
		
		return isSolvable; 
	}
	
	
	/**
	 * Get a computed solution to the puzzle. 
	 * 
	 * A call to this method return senseful results only
	 * when being called after a call to foundSolution() has 
	 * been done.
	 * 
	 * Returns: the most recent solution to the puzzle of the solver
	 */
	public Puzzle solution()
	out(result)
	{
		if(result !is null ) { 
			assert ( result.solutionOf(puzzle) );
		}
	}
	body
	{
		return previousSolution;
	}
	
}
