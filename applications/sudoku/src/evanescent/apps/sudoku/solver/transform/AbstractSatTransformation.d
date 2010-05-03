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
module evanescent.apps.sudoku.solver.transform.AbstractSatTransformation;

private import evanescent.apps.sudoku.solver.transform.ISatTransformation;
private import evanescent.apps.sudoku.solver.transform.PropositionalSignature;
private import evanescent.deescover.core.Solver; 
private import evanescent.deescover.core.SolverTypes;
private import evanescent.apps.sudoku.core.Puzzle;

/**
 * An abstract base class for various SAT transformations.
 * 
 * Implements the target solver and signature management 
 * which can be reused in the various transformations. 
 * Also provides the mapping back to a Puzzle.
 *
 * Authors: Uwe Keller
 */
abstract class AbstractSatTransformation : ISatTransformation {
	
	protected Solver solver;
	protected PropositionalSignature signature; 
	protected Puzzle puzzle; 
	
	// ----------------------------------------------
	// Constructors & Destructors
	// ----------------------------------------------

	public this(Solver solver, PropositionalSignature signature)
	{
		setTargetSolver(solver);
		setSignature(signature);
	}

	// ----------------------------------------------
	// Methods
	// ----------------------------------------------

	
	public void setTargetSolver(Solver satSolver)
	{
		solver = satSolver; 
	}
	
	public void setSignature(PropositionalSignature propSymbols)
	{
		signature = propSymbols; 
	}
	
	public void transform(Puzzle p)
	{
		puzzle = p; 	
		doTransform();
	}
	
	/**
	 * This method should only be called after: 
	 * 
	 * 1. a call to transform, and 
	 * 2. a call to the SAT solver which computed the satisfiability of
	 * the SAT problem corresponding to the input puzzle. 
	 * 
	 * Returns: a solution to the SUDOKU puzzle which has been transformed
	 * last (and solved by the SAT solver)
	 *  
	 */
	public Puzzle solution()
	{
		Puzzle result = new Puzzle(puzzle.width(), puzzle.height());
		
		for (Var i = 0; i < solver.nVars(); i++){
			if (solver.modelValueOfVar(i) == LBool.L_TRUE)
			{
				result.setEntry(
						signature.row(i), 
						signature.column(i), 
						cast(Symbol) signature.value(i) 
					); 
			}
		}
		
		return result; 
	}

	
	abstract protected void doTransform(); 
	
}


