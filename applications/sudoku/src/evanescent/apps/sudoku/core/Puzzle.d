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


module evanescent.apps.sudoku.core.Puzzle; 

private import Integer = tango.text.convert.Integer;
private import tango.math.Math;
private import tango.text.convert.Layout;

debug{
	private import tango.io.Stdout; 
}

/**
 * A model class for representing general SUDOKU puzzle instances.
 * 
 * A generalized SUDOKU puzzle contains of rectangular regions
 * with witdth w and height h that are organized in a grid.
 *
 * Each rectangular region contains w*h squares that can contain
 * numbers from 1 to w*h. 
 * 
 * The overall grid of the puzzle contains h columns and w rows.
 * These numbers ensure later on that each row and each column 
 * can contain exactly each number from 1 to w*h exactly once.   
 *
 * Authors: Uwe Keller 
 *
 */
public typedef int Symbol = -1; 
public final static  Symbol FREE_SQUARE = -1;


public char[] symbolToString(Symbol s){
	if (s != FREE_SQUARE) {
		return Integer.toString(cast(int) s);
	} else {
		return "x";
	}
}

public class Puzzle {
	
	/* The with of a region of the puzzle */
	private uint width_; 

	/* The height of a region of the puzzle */
	private uint height_;

	private Symbol[][] entries;

	// ----------------------------------------------
	// Constructor and Destructor
	// ----------------------------------------------

	/**
	 * Create an empty puzzle using rectangular regions
	 * of width $(I width) and height $(I height). 
	 * The puzzle therefore consists of $(I width x height)
	 * cells. 
	 *
	 * Params: 
	 * 		width = width of a rectangular subregion
	 *      height = height of a rectangular subregion
	 */
	public this (uint width, uint height)
	in {
		assert ( width > 1 ); 
		assert ( height > 1 ); 
		
	}
	body {
		width_ = width;
		height_ = height;

		entries = new Symbol[][](width_ * height_, width_ * height_);
		
	}

	// ----------------------------------------------
	// Methods
	// ----------------------------------------------

	public final uint width()
	{
		return this.width_;
	}
	
	public final uint height()
	{
		return this.height_;
	}

	public final uint numberOfRows()
	{
		return width_ * height_;
	}

	public final uint numberOfColumns()
	{
		return width_ * height_;
	}

	/**
	 * Retrieve the entry of a cell in the puzzle.
	 * 
	 * Please note that coordinates are 0-based. 
	 * 
	 * Params:
	 *     row = the row of the cell (0 <= row < numberOfRows() ) 
	 *     column = the column of the cell (0 <= columns < numberOfColumns() ) 
	 * Returns:
	 *  	the symbol that is assigned to the cell. Empty cells have
	 *      the special entry FREE_SQUARE.
	 */
	public Symbol entry(uint row, uint column)
	in {
		assert( row < numberOfRows() ); 
		assert( column < numberOfColumns() ); 
	}
	body {
		return entries[ row ][ column  ];
	}

	/**
	 * Set the entry of a cell in the puzzle.
	 * 
	 * Please note that coordinates are 0-based. 
	 * 
	 * Params:
	 *     row = the row of the cell (0 <= row < numberOfRows() ) 
	 *     column = the column of the cell (0 <= columns < numberOfColumns() ) 
	 *     s = the symbol that shall serve as the entry for the cell
	 */
	public void setEntry(uint row, uint column, Symbol s)
	in {
		assert( row < numberOfRows() ); 
		assert( column < numberOfColumns() ); 
	}
	body {
		entries[ row ][ column  ] = s;
	}
	
	public void removeEntry(uint row, uint column)
	{
		setEntry(row, column, FREE_SQUARE);
	}
	
	/**
	 * Check if the puzzle is fully filled in.
	 * Returns: true iff. there are no free squares left in
	 * the puzzle
	 */
	public bool completed()
	{ 
		foreach (row ; entries) {
			foreach (e ; row ) {
				if (e == FREE_SQUARE) { return false; }
			}
		}
		return true; 
	}
	
	/**
	 * Check if this puzzle extends the given puzzle p, i.e.
	 * if the puzzle has the same dimension than p and 
	 * contains at least all the hints (or cell assigments)
	 * in puzzle p. Additionally, this puzzle can assign 
	 * values to other cells. 
	 * 
	 * Any extension of p can therefore be created by filling 0 or more
	 * cells in p. 
	 * 
	 * A special case of an extension is the solution of a (solvable) SUDOKU puzzle.
	 * 
	 * Params:
	 *     p = the puzzle to be extended
	 * Returns:
	 * 	   true iff this puzzle is an extension of p 
	 */
	public bool extends(Puzzle p)
	{
		if (width() != p.width() || height() != p.height() ) { return false; }
		
		for (uint c = 0; c < p.numberOfColumns(); c++)
		{
			for (uint r = 0; r < p.numberOfRows(); r++)
			{
				if (p.entry(r,c) != FREE_SQUARE && p.entry(r,c) != entry(r,c)) { return false; }
			}
		}
		
		return true; 
	}
	
	/**
	 * Checks if this puzzle represents a solution of a given puzzle.
	 * Params:
	 *     p = the puzzle to be compared to
	 * Returns: true iff. this puzzle extends p, is fully filled in and valid.
	 * 
	 */
	public bool solutionOf(Puzzle p)
	{
		return this.completed() && this.extends(p) && this.valid(); 
	}
	
	/**
	 * Returns: true iff the cells that are filled in satisfy the SUDOKU
	 * constraints on rows, columns, and regions.
	 */
	public bool valid()
	{
		return satisfiesRowConstraints() &&  satisfiesColumnConstraints() && satisfiesRegionConstraints();
	}
	
	protected bool satisfiesRowConstraints()
	{
		for (uint r = 0; r < numberOfRows(); r++)
		{
			Symbol[] rowEntries = []; 
			for (uint c = 0; c < numberOfColumns(); c++)
			{
			  rowEntries ~= entry(r,c); 
			}
			
			// Stdout.formatln("rowEntries #{} : [{}]", r, rowEntries);
			
			if (rowEntries.length != numberOfRows() || containsDuplicates(rowEntries))
			{
				return false;
			} 
			
		}
		return true;

	}
	
	protected bool satisfiesColumnConstraints()
	{
		
		for (uint c = 0; c < numberOfColumns(); c++)
		{
			Symbol[] columnEntries = []; 
			for (uint r = 0; r < numberOfRows(); r++)
			{
			  columnEntries ~= entry(r,c); 
			}
			
			// Stdout.formatln("columnEntries #{} : [{}]", c, columnEntries);
			
			if (columnEntries.length != numberOfColumns() || containsDuplicates(columnEntries))
			{
				return false;
			} 
			
		}
		return true;

	}
	
	protected bool containsDuplicates(Symbol[] list)
	{
		if (list.length == 0) { return false; }
		
		list.sort;
		
		Symbol last = list[0]; 
		for (uint i = 1; i < list.length; i++)
		{
			if (list[i] == last && list[i] != FREE_SQUARE) { return true; }
			last = list[i];
		}
		
		return false; 
	}
	
	protected bool satisfiesRegionConstraints()
	{
		for (uint x = 0; x < height() ; x++)
		{
			for (uint y = 0; y < width() ; y++)
			{
				if (!satisfiesRegionConstraints(x,y)) { return false; }
			}	
		}
		return true;
	}
	
	protected bool satisfiesRegionConstraints(uint x, uint y)
	{
		Symbol[] regionEntries = []; 
		for (uint i = 0; i < numberOfColumns(); i++)
		{	
			uint c = x * width() + i % width(); 
			uint r = y * height() + i / width(); 
			regionEntries ~= entry(r,c); 	
		}
		
		// Stdout.formatln("regionEntries ({},{}) : [{}]", x,y, regionEntries);
		
		if (regionEntries.length != numberOfColumns() || containsDuplicates(regionEntries))
		{
			return false;
		}
		return true;
	}
	
	
	


	/**
	 * Returns: the number of cells that are filled in (i.e. have an entry different from FREE_SQUARE)
	 */
	public uint numberOfHints()
	{
		int cnt = 0; 
		foreach (row ; entries) {
			foreach (e ; row ) {
				if (e != FREE_SQUARE) { cnt++; }
			}
		}
		return cnt; 
	}
	
	
	
	public char[] toString()
	{
		char[] s = "";
		auto column_index = 0; 
		auto row_index = 0;
		
		auto layout = new Layout!(char);

		char[] l; 
		uint max_entry_length = 1 + cast(uint) floor(log10(numberOfColumns())); 
		uint max_line_width = (1 + (numberOfColumns() / width()) * (2 + width() * (1 + max_entry_length))  ); 
	 
		foreach (row ; entries) {
			row_index++;
			column_index = 0;
			l = ""; 
			
			foreach (e ; row ) {
				column_index++;
				
				if ((column_index - 1) % width() == 0 ){
					l ~= "| ";
				}
				
				l ~= layout.convert("{," ~ Integer.toString(max_entry_length) ~ "}" , symbolToString(e));
				l ~= " ";
				
				if (column_index == numberOfColumns()){
					l ~= "|";
				}
			}
			
			
			s = s ~ l ~ "\n";
			if (row_index % height() == 0) { s ~= generate_line("-",  max_line_width) ~ "\n"; }
		}
		
		s = generate_line("-",  max_line_width) ~ "\n" ~  s; 
	
		return s;
	}
	
	private char[] generate_line(char[] s, uint l)
	{
		char[] result = "";
		while (l--){
			result ~= s; 
		}
		return result; 
	} 


	
} 