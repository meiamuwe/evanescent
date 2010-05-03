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
module evanescent.apps.sudoku.solver.transform.SolutionNotExtendingPuzzleRequirement;

private import evanescent.apps.sudoku.solver.transform.AbstractSatTransformation;
private import evanescent.apps.sudoku.solver.transform.ISatTransformation;
private import evanescent.apps.sudoku.solver.transform.PropositionalSignature;
private import evanescent.deescover.core.Solver;
private import evanescent.deescover.core.SolverTypes;
import evanescent.deescover.core.clause.Clause;
private import evanescent.deescover.util.Vec;


private import tango.io.Stdout; 
/**
 * Transforms a puzzle into a propositional theory that specifies
 * that a solution should not extend the given puzzle. 
 * 
 * More specifically, the generated propositional theory states that 
 * a cell assignment for a puzzle of the same size should be 
 * different in at least on cell that is already filled in the puzzle.
 *
 * This requirement can be used for instance to check to generate
 * additional solutions to a puzzle which are different from a given
 * solution. 
 * 
 * Hence, we can also use this requirement to check the unique solvability
 * of a puzzle.
 * 
 * Authors: Uwe Keller
 */
class SolutionNotExtendingPuzzleRequirement : AbstractSatTransformation
{

	// ----------------------------------------------
	// Constructors
	// ----------------------------------------------

	public this(Solver solver, PropositionalSignature signature)
	{
		super(solver, signature);
	}
	
	// ----------------------------------------------
	// Methods
	// ----------------------------------------------


	protected void doTransform()
	{
		// Stdout.formatln("Another Transform applied to \n {}", puzzle); 
		add_constraints_different_for_at_least_one_filled_cell();
		
	}
	
	protected void add_constraints_different_for_at_least_one_filled_cell()
	{
		// There is at least one number in each field
		Vec!(Lit) clause = new Vec!(Lit)();
		for(int c = 0; c < puzzle.numberOfColumns(); c++)
		{
			for(int r = 0; r < puzzle.numberOfRows(); r++)
			{
				if ( puzzle.hasFilledCellAt(r,c) ) 
				{
					clause.push( getLiteral(signature.variable(c, r, puzzle.entry(r,c) ),false) );
				} 
			}
		}
		
		/*
		Stdout.formatln("Added clause of size : {}", clause.size()).flush();
		for (int i = 0; i< clause.size(); i++ )
		{
			Lit l = clause[i];
			Var var = var(clause[i]); 
			
			Stdout.formatln("Added lit #{} : {} / {}<{},{},{}> ", 
					i, l, 
					(!sign(l) ? "not": "" ), 
					signature.row(var), 
					signature.column(var), 
					signature.value(var)   ).flush(); 
		}
		
		*/
		
		solver.addClause(clause);
	}

}