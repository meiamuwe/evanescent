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


module evanescent.apps.sudoku.solver.SatTransformation;


private import evanescent.deescover.core.SolverTypes; 
private import evanescent.deescover.core.Solver;
private import evanescent.deescover.core.clause.Clause;
private import evanescent.deescover.util.Vec;

private import evanescent.apps.sudoku.core.Puzzle;


/**
 * A transformation of SUDOKU puzzles to propositional
 * logic.
 * 
 * For a SUDOKU puzzle P, the transformation generates a 
 * formula F(P) for with the following formal property: 
 * 
 * An interpretation I is a model of F(P)
 * iff
 * puzzle(I) is a solution of the SUDOKU puzzle P
 * 
 * The transformation follows the non-minimal (i.e. redundant) formulation
 * of SUDOKU puzzles in propositional logic discussed in the paper:
 * 
 * $(B I. Lynce and J. Ouaknine) $(I Sudoku as a SAT Problem), 9th International Symposium on Artificial Intelligence and Mathematics, January 2006. 
 * 
 *  
 * 
 * 
 * Authors: Uwe Keller
 */
class SatTransformation {

	alias Var[][][] VariablePool; 
	
	private Solver solver;  
	
	private uint[Var] rowForVar; 
	private uint[Var] columnForVar; 
	private uint[Var] valueForVar; 
	
	private VariablePool vars;
	private Puzzle p; 
	
	// ----------------------------------------------
	// Constructor and Destructor
	// ----------------------------------------------

	
	public this (Solver satSolver)
	{
		solver = satSolver; 
	}



	// ----------------------------------------------
	// Methods
	// ----------------------------------------------

	public void transform(Puzzle p)
	{
		this.p = p;
		vars = generatePropositionalVariables(p); 
		// generate clauses and stuff them into the solver given in the constructor
		
		// The generated constraints are not minimal (i.e. they represent
		// redundant information) but the redudancy helps the solver to
		// find solutions faster
		
		add_constraints_puzzle_fully_filled_in(p); 
		add_constraints_at_most_one_entry_per_cell(p);
		add_constraints_every_entry_at_most_once_in_each_column(p); 
		add_constraints_every_entry_at_most_once_in_each_row(p);
		add_constraints_every_entry_at_most_once_in_each_region(p);

		add_constraints_every_entry_at_least_once_in_each_column(p); 
		add_constraints_every_entry_at_least_once_in_each_row(p);
		add_constraints_every_entry_at_least_once_in_each_region(p);
		
		add_constraints_given_hints(p);
		
	}
	
	public VariablePool generatePropositionalVariables(Puzzle p)
	{
		// Var[column - 1][row - 1][value - 1]
		// Var[][][] vars = new Var[p.numberOfColumns()][p.numberOfRows()][p.numberOfColumns()];

		Var[][][] vars = 
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
		return vars;

	}



	
	public void add_constraints_puzzle_fully_filled_in(Puzzle p)
	{
		// There is at least one number in each field
		Vec!(Lit) clause = new Vec!(Lit)(); 
		for (int c = 0; c < p.numberOfColumns(); c++)
		{
			for (int r = 0; r < p.numberOfRows(); r++)
			{
				clause.clear();
				
				for (int val = 1; val <= p.numberOfColumns(); val++)
				{
					clause.push( getLiteral(vars[c][r][val]) ); 
				}
				
				solver.addClause(clause);
			}
		}
	}
	
	public void add_constraints_at_most_one_entry_per_cell(Puzzle p)
	{
		// There is at most one value in each cell of the puzzle 
		Vec!(Lit) clause = new Vec!(Lit)(); 
		for (int c = 0; c < p.numberOfColumns(); c++)
		{
			for (int r = 0; r < p.numberOfRows(); r++)
			{
				for (int val1 = 1; val1 <= p.numberOfColumns(); val1++)
				{
					for (int val2 = val1 + 1; val2 <= p.numberOfColumns(); val2++)
					{
						clause.clear();
						clause.push( getLiteral(vars[c][r][val1], false) ); 
						clause.push( getLiteral(vars[c][r][val2], false) );
						solver.addClause(clause);
					} 
				}
			}
		}
	}

	public void add_constraints_every_entry_at_most_once_in_each_row(Puzzle p)
	{
		// Every value occurs at most once in each row of the puzzle
		Vec!(Lit) clause = new Vec!(Lit)(); 
		for (int c1 = 0; c1 < p.numberOfColumns() - 1; c1++)
		{
			for (int c2 = c1 + 1; c2 < p.numberOfColumns; c2++)
			{
				for (int r = 0; r < p.numberOfRows(); r++)
				{
					for (int val = 1; val <= p.numberOfColumns(); val++)
					{
						clause.clear();
						clause.push( getLiteral(vars[c1][r][val], false) ); 
						clause.push( getLiteral(vars[c2][r][val], false) );
						solver.addClause(clause);
					}
				}
			}
		}
	}

	public void add_constraints_every_entry_at_most_once_in_each_column(Puzzle p)
	{
		// Every value occurs at most once in each column of the puzzle
		Vec!(Lit) clause = new Vec!(Lit)(); 
		for (int c = 0; c < p.numberOfColumns(); c++)
		{
			for (int r1 = 0; r1 < p.numberOfRows() - 1; r1++)
			{
				for (int r2 = r1 + 1; r2 < p.numberOfRows(); r2++)
				{
					for (int val = 1; val <= p.numberOfColumns(); val++)
					{
						clause.clear();
						clause.push( getLiteral(vars[c][r1][val], false) ); 
						clause.push( getLiteral(vars[c][r2][val], false) );
						solver.addClause(clause);
					}
				}
			}
		}
	}
	
	public void add_constraints_every_entry_at_most_once_in_each_region(Puzzle p)
	{
		// Every value occurs at most once in each region of the puzzle
		
		for (int c = 0; c < p.numberOfColumns() / p.width(); c++)
		{
			for (int r = 0; r < p.numberOfRows() / p.height(); r++)
			{
				add_constraints_every_entry_at_most_once_in_region(c, r, p);
			}
		}
		
	}
	
	
	public void add_constraints_every_entry_at_most_once_in_region(uint w, uint h, Puzzle p)
	{
		// Every value occurs at most once in the region with 
		// coordinates (w,h) of the puzzle
		
		Vec!(Lit) clause = new Vec!(Lit)(); 
		
		uint nofCellsInRegion = p.width() * p.height();
		
		for (int val = 1; val <= p.numberOfColumns(); val++)
		{
			for (int i = 0; i < nofCellsInRegion; i++)
			{
				for (int j = i+1; j < nofCellsInRegion; j++)
				{
					uint cell_i_x = w * p.width() + i %  p.width(); 
					uint cell_i_y = h * p.height() + i / p.width();

					uint cell_j_x = w * p.width() + j %  p.width(); 
					uint cell_j_y = h * p.height() + j / p.width();

					clause.clear();
					clause.push( getLiteral(vars[cell_i_x][cell_i_y][val], false) ); 
					clause.push( getLiteral(vars[cell_j_x][cell_j_y][val], false) ); 
					solver.addClause(clause);

				}
			}
		}
		
	}
	
	public void add_constraints_every_entry_at_least_once_in_each_row(Puzzle p)
	{
		// Every value occurs at least once in each row of the puzzle
		Vec!(Lit) clause = new Vec!(Lit)(); 
		
		for (int r = 0; r < p.numberOfRows(); r++)
		{
			for (int val = 1; val <= p.numberOfColumns(); val++)
			{
				clause.clear();
				for (int c = 0; c < p.numberOfColumns(); c++)
				{
					clause.push( getLiteral(vars[c][r][val]) ); 
				}
				solver.addClause(clause);
			}
		}
	}

	public void add_constraints_every_entry_at_least_once_in_each_column(Puzzle p)
	{
		// Every value occurs at least once in each column of the puzzle
		Vec!(Lit) clause = new Vec!(Lit)(); 
		
		for (int c = 0; c < p.numberOfColumns(); c++)
		{
			for (int val = 1; val <= p.numberOfColumns(); val++)
			{
				clause.clear();
				for (int r = 0; r < p.numberOfRows(); r++)
				{
					clause.push( getLiteral(vars[c][r][val]) ); 
				}
				solver.addClause(clause);
			}
		}
	}
	
	public void add_constraints_every_entry_at_least_once_in_each_region(Puzzle p)
	{
		// Every value occurs at least once in each region of the puzzle
		
		for (int c = 0; c < p.numberOfColumns() / p.width(); c++)
		{
			for (int r = 0; r < p.numberOfRows() / p.height(); r++)
			{
				add_constraints_every_entry_at_least_once_in_region(c, r, p);
			}
		}
		
	}
	
	
	public void add_constraints_every_entry_at_least_once_in_region(uint w, uint h, Puzzle p)
	{
		// Every value occurs at most once in the region with 
		// coordinates (w,h) of the puzzle
		
		Vec!(Lit) clause = new Vec!(Lit)(); 
		
		uint nofCellsInRegion = p.width() * p.height();
		
		for (int val = 1; val <= p.numberOfColumns(); val++)
		{
			clause.clear();
			
			for (int i = 0; i < nofCellsInRegion; i++)
			{
				uint cell_i_x = w * p.width() + i %  p.width(); 
				uint cell_i_y = h * p.height() + i / p.width();

				clause.push( getLiteral(vars[cell_i_x][cell_i_y][val]) ); 
			}
			
			solver.addClause(clause);
		}
		
	}
	
	public void add_constraints_given_hints(Puzzle p)
	{
		Vec!(Lit) clause = new Vec!(Lit)(); 
		for (int c = 0; c < p.numberOfColumns(); c++)
		{
			for (int r = 0; r < p.numberOfRows(); r++)
			{
				if (p.entry(r,c) != FREE_SQUARE)
				{
					clause.clear();
					clause.push( getLiteral(vars[c][r][p.entry(r,c)]) ); 
					solver.addClause(clause);
				}
				
			}
		}
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
		Puzzle result = new Puzzle(p.width(), p.height());
		
		for (Var i = 0; i < solver.nVars(); i++){
			if (solver.modelValueOfVar(i) == LBool.L_TRUE)
			{
				result.setEntry(row(i), column(i), cast(Symbol) value(i)); 
			}
		}
		
		return result; 
	}
	
	private uint row(Var i)
	{
		return rowForVar[i];
	}
	
	private uint column(Var i)
	{
		return columnForVar[i];
	}
	
	private uint value(Var i)
	{
		return valueForVar[i];
	}
	
}
	