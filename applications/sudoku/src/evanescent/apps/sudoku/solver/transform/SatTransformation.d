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


module evanescent.apps.sudoku.solver.transform.SatTransformation;

private import evanescent.deescover.core.SolverTypes; 
private import evanescent.deescover.core.Solver;
private import evanescent.deescover.core.clause.Clause;
private import evanescent.deescover.util.Vec;

private import evanescent.apps.sudoku.core.Puzzle;

private import evanescent.apps.sudoku.solver.transform.PropositionalSignature;
private import evanescent.apps.sudoku.solver.transform.AbstractSatTransformation;

import tango.io.Stdout;

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
class SatTransformation : AbstractSatTransformation {

	private Puzzle p; 


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
		// The generated constraints are not minimal (i.e. they represent
		// redundant information) but the redudancy helps the solver to
		// find solutions faster
		
		add_constraints_puzzle_fully_filled_in(); 
		add_constraints_at_most_one_entry_per_cell();
		
		add_constraints_every_entry_at_most_once_in_each_column(); 
		add_constraints_every_entry_at_most_once_in_each_row();
		add_constraints_every_entry_at_most_once_in_each_region();

		add_constraints_every_entry_at_least_once_in_each_column(); 
		add_constraints_every_entry_at_least_once_in_each_row();
		add_constraints_every_entry_at_least_once_in_each_region();
		
		add_constraints_given_hints();
		
	}
	
	

	
	protected void add_constraints_puzzle_fully_filled_in()
	{
		// There is at least one number in each field
		Vec!(Lit) clause = new Vec!(Lit)(); 
		for (int c = 0; c < puzzle.numberOfColumns(); c++)
		{
			for (int r = 0; r < puzzle.numberOfRows(); r++)
			{
				clause.clear();
				
				for (int val = 1; val <= puzzle.numberOfColumns(); val++)
				{
					clause.push( getLiteral(signature.variable(c,r,val)) ); 
				}
				
				solver.addClause(clause);
			}
		}
	}
	
	protected void add_constraints_at_most_one_entry_per_cell()
	{
		// There is at most one value in each cell of the puzzle 
		Vec!(Lit) clause = new Vec!(Lit)(); 
		for (int c = 0; c < puzzle.numberOfColumns(); c++)
		{
			for (int r = 0; r < puzzle.numberOfRows(); r++)
			{
				for (int val1 = 1; val1 <= puzzle.numberOfColumns(); val1++)
				{
					for (int val2 = val1 + 1; val2 <= puzzle.numberOfColumns(); val2++)
					{
						clause.clear();
						clause.push( getLiteral(signature.variable(c,r,val1), false) ); 
						clause.push( getLiteral(signature.variable(c,r,val2), false) );
						solver.addClause(clause);
					} 
				}
			}
		}
	}

	protected void add_constraints_every_entry_at_most_once_in_each_row()
	{
		// Every value occurs at most once in each row of the puzzle
		Vec!(Lit) clause = new Vec!(Lit)(); 
		for (int c1 = 0; c1 < puzzle.numberOfColumns() - 1; c1++)
		{
			for (int c2 = c1 + 1; c2 < puzzle.numberOfColumns; c2++)
			{
				for (int r = 0; r < puzzle.numberOfRows(); r++)
				{
					for (int val = 1; val <= puzzle.numberOfColumns(); val++)
					{
						clause.clear();
						clause.push( getLiteral(signature.variable(c1,r,val), false) ); 
						clause.push( getLiteral(signature.variable(c2,r,val), false) );
						solver.addClause(clause);
					}
				}
			}
		}
	}

	protected void add_constraints_every_entry_at_most_once_in_each_column()
	{
		// Every value occurs at most once in each column of the puzzle
		Vec!(Lit) clause = new Vec!(Lit)(); 
		for (int c = 0; c < puzzle.numberOfColumns(); c++)
		{
			for (int r1 = 0; r1 < puzzle.numberOfRows() - 1; r1++)
			{
				for (int r2 = r1 + 1; r2 < puzzle.numberOfRows(); r2++)
				{
					for (int val = 1; val <= puzzle.numberOfColumns(); val++)
					{
						clause.clear();
						clause.push( getLiteral(signature.variable(c,r1,val), false) ); 
						clause.push( getLiteral(signature.variable(c,r2,val), false) );
						solver.addClause(clause);
					}
				}
			}
		}
	}
	
	protected void add_constraints_every_entry_at_most_once_in_each_region()
	{
		// Every value occurs at most once in each region of the puzzle
		
		for (int c = 0; c < puzzle.numberOfColumns() / puzzle.width(); c++)
		{
			for (int r = 0; r < puzzle.numberOfRows() / puzzle.height(); r++)
			{
				add_constraints_every_entry_at_most_once_in_region(c, r);
			}
		}
		
	}
	
	
	protected void add_constraints_every_entry_at_most_once_in_region(uint w, uint h)
	{
		// Every value occurs at most once in the region with 
		// coordinates (w,h) of the puzzle
		
		Vec!(Lit) clause = new Vec!(Lit)(); 
		
		uint nofCellsInRegion = puzzle.width() * puzzle.height();
		
		for (int val = 1; val <= puzzle.numberOfColumns(); val++)
		{
			for (int i = 0; i < nofCellsInRegion; i++)
			{
				for (int j = i+1; j < nofCellsInRegion; j++)
				{
					uint cell_i_x = w * puzzle.width() + i %  puzzle.width(); 
					uint cell_i_y = h * puzzle.height() + i / puzzle.width();

					uint cell_j_x = w * puzzle.width() + j %  puzzle.width(); 
					uint cell_j_y = h * puzzle.height() + j / puzzle.width();

					clause.clear();
					clause.push( getLiteral( signature.variable(cell_i_x,cell_i_y,val), false) ); 
					clause.push( getLiteral( signature.variable(cell_j_x,cell_j_y,val), false) ); 
					solver.addClause(clause);

				}
			}
		}
		
	}
	
	protected void add_constraints_every_entry_at_least_once_in_each_row()
	{
		// Every value occurs at least once in each row of the puzzle
		Vec!(Lit) clause = new Vec!(Lit)(); 
		
		for (int r = 0; r < puzzle.numberOfRows(); r++)
		{
			for (int val = 1; val <= puzzle.numberOfColumns(); val++)
			{
				clause.clear();
				for (int c = 0; c < puzzle.numberOfColumns(); c++)
				{
					clause.push( getLiteral(signature.variable(c,r,val) )); 
				}
				solver.addClause(clause);
			}
		}
	}

	protected void add_constraints_every_entry_at_least_once_in_each_column()
	{
		// Every value occurs at least once in each column of the puzzle
		Vec!(Lit) clause = new Vec!(Lit)(); 
		
		for (int c = 0; c < puzzle.numberOfColumns(); c++)
		{
			for (int val = 1; val <= puzzle.numberOfColumns(); val++)
			{
				clause.clear();
				for (int r = 0; r < puzzle.numberOfRows(); r++)
				{
					clause.push( getLiteral( signature.variable(c,r,val) )); 
				}
				solver.addClause(clause);
			}
		}
	}
	
	protected void add_constraints_every_entry_at_least_once_in_each_region()
	{
		// Every value occurs at least once in each region of the puzzle
		
		for (int c = 0; c < puzzle.numberOfColumns() / puzzle.width(); c++)
		{
			for (int r = 0; r < puzzle.numberOfRows() / puzzle.height(); r++)
			{
				add_constraints_every_entry_at_least_once_in_region(c, r);
			}
		}
		
	}
	
	
	protected void add_constraints_every_entry_at_least_once_in_region(uint w, uint h)
	{
		// Every value occurs at most once in the region with 
		// coordinates (w,h) of the puzzle
		
		Vec!(Lit) clause = new Vec!(Lit)(); 
		
		uint nofCellsInRegion = puzzle.width() * puzzle.height();
		
		for (int val = 1; val <= puzzle.numberOfColumns(); val++)
		{
			clause.clear();
			
			for (int i = 0; i < nofCellsInRegion; i++)
			{
				uint cell_i_x = w * puzzle.width() + i %  puzzle.width(); 
				uint cell_i_y = h * puzzle.height() + i / puzzle.width();

				clause.push( getLiteral( signature.variable(cell_i_x, cell_i_y, val ) )); 
			}
			
			solver.addClause(clause);
		}
		
	}
	
	protected void add_constraints_given_hints()
	{
		Vec!(Lit) clause = new Vec!(Lit)(); 
		for (int c = 0; c < puzzle.numberOfColumns(); c++)
		{
			for (int r = 0; r < puzzle.numberOfRows(); r++)
			{
				if (puzzle.hasFilledCellAt(r,c))
				{
					clause.clear();
					clause.push( getLiteral( signature.variable(c,r,puzzle.entry(r,c)) )); 
					solver.addClause(clause);
				}
				
			}
		}
	}
	
	
		
	
}
	