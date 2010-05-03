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

module evanescent.apps.sudoku.solver.transform.PropositionalSignature;

private import evanescent.deescover.core.SolverTypes;
private import evanescent.deescover.core.Solver;
private import evanescent.apps.sudoku.core.Puzzle;


/**
 * A class implementing the creation and management of 
 * a propositional signature for SUDOKU puzzles.
 * 
 * The signature constructs propositional variables to represent
 * a SUDOKU puzzle
 * 
 * Authors: Uwe Keller
 */
class PropositionalSignature {
	
	
	alias Var[][][] VariablePool; 
	
	private uint[Var] rowForVar; 
	private uint[Var] columnForVar; 
	private uint[Var] valueForVar; 
	
	private uint heightOfPuzzle; 
	private uint widthOfPuzzle;
	
	private VariablePool vars;
	
	private Solver solver; 


	// ----------------------------------------------
	// Constructors & Destructors
	// ----------------------------------------------

	/**
	 * Create a propositional signature for the given
	 * puzzle. The signature  
	 * 
	 * The propositional variables are managed by the
	 * specified SAT solver. 
	 *  
	 */
	public this(Puzzle p, Solver satSolver) 
	{
		widthOfPuzzle = p.width(); 
		heightOfPuzzle = p.height();
		solver = satSolver; 
		
		generatePropositionalVariablesFor(p);
		
	}
	
	public ~this()
	{
		solver = null;
		vars.length = 0;
	}
	
	
		
	// ----------------------------------------------
	// Methods
	// ----------------------------------------------

	/**
	 * A cell assignment (row,column) -> value is represented
	 * by a propositional variable <row,column,value>. 
	 * 
	 * This method allows extract the row index for the cell
	 * assignment in the SUDOKU puzzle 
	 * that a propositional variable stands for.
	 * 
	 * Returns: the row index of a propositional variable
	 */
	public uint row(Var i)
	{
		return rowForVar[i];
	}
	

	/**
	 * A cell assignment (row,column) -> value is represented
	 * by a propositional variable <row,column,value>. 
	 * 
	 * This method allows extract the column index for the cell
	 * assignment in the SUDOKU puzzle 
	 * that a propositional variable stands for.
	 * 
	 * Returns: the column index of a propositional variable
	 */
	
	public uint column(Var i)
	{
		return columnForVar[i];
	}
	

	/**
	 * A cell assignment (row,column) -> value is represented
	 * by a propositional variable <row,column,value>. 
	 * 
	 * This method allows extract the value for the cell
	 * assignment in the SUDOKU puzzle 
	 * that a propositional variable stands for.
	 * 
	 * Returns: the value of assignment represented by the 
	 * propositional variable
	 */
	public uint value(Var i)
	{
		return valueForVar[i];
	}
	
	
	public Var variable(uint column, uint row, uint value)
	{
		return vars[column][row][value]; 
	}
	
	/**
	 * Checks if the propositional signature can be used
	 * to represent and reason about the given puzzle.
	 * 
	 * More specifically, a propositional signature can be applied
	 * to a puzzle, if the signature has been generated for a puzzle
	 * of the same dimensions. 
	 * 
	 * Params:
	 *     p = puzzle for which to reuse the signature 
	 *     
	 * Returns: true iff. the signature can be used to describe, 
	 * represent and reason about properties of the given puzzle
	 */
	public bool isApplicableTo(Puzzle p)
	{
		return (p.height() == heightOfPuzzle && p.width() == widthOfPuzzle); 
	}
	
	/**
	 * Generates the propositional variables to represent properties
	 * of a SUDOKU puzzle. 
	 * 
	 * A cell assignment (row,column) -> value is represented
	 * by a propositional variable <row,column,value>. 
	 * 
	 * Propositional formulae related to SUDOKU puzzles 
	 * always refer to cell assignments. 
	 * 
	 * Params:
	 *     p = the puzzle to be represented
	 */
	
	private void generatePropositionalVariablesFor(Puzzle p)
	{
		// Var[column - 1][row - 1][value]
	
		vars = 
			new Var[][][] (p.numberOfColumns(), p.numberOfRows(), p.numberOfColumns() +1 );
		
		// empty the associative arrays for the inverse mapping of propositional variables
		// to the sudoku puzzle entries
		foreach (Var key ; rowForVar.keys) rowForVar.remove(key);
		foreach (Var key ; columnForVar.keys) columnForVar.remove(key);
		foreach (Var key ; valueForVar.keys) valueForVar.remove(key);
		
		
		for (int c = 0; c < p.numberOfColumns(); c++)
		{
			for (int r = 0; r < p.numberOfRows(); r++)
			{
				for (int val = 1; val <= p.numberOfColumns(); val++)
				{
					Var variable = solver.newVar();
					vars[c][r][val] = variable;

					rowForVar[variable] = r; 
					columnForVar[variable] = c; 
					valueForVar[variable] = val; 

				}
			}
		}
		
	}


	
}