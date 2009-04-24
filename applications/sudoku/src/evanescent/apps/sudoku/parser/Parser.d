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


module evanescent.apps.sudoku.parser.Parser; 

import evanescent.apps.sudoku.core.Puzzle;
private import tango.io.model.IConduit : InputStream ;
private import tango.text.Util : delimiters, trim;
private import tango.text.stream.LineIterator;
private import tango.core.Exception;


/**
 * A parser for a simple ASCII representation of 
 * SUDOKU puzzle instances.
 * 
 * Authors: Uwe Keller 
 *
 */
 
public class SudokuParser {
	
	protected static final char COMMENT_LINE_INDICATOR = 'c';
	protected static final char PROBLEM_METADATA_LINE_INDICATOR = 'p';

	
	// ----------------------------------------------
	// Constructor and Destructor
	// ----------------------------------------------

	
	// ----------------------------------------------
	// Methods
	// ----------------------------------------------

	public Puzzle parse(InputStream input)
	{
		Puzzle problem = null;
		
		uint entryCnt = 0; 

		// Split up the input stream into lines (separated by newline symbols)
		auto lines = new LineIterator!(char) (input);
		scope(exit) { lines.close(); }

		uint lineNumber = 0;
		while (lines.next()) {
			
			char[] line = trim!(char)(lines.get());
			
			lineNumber++;
			
			if (line.length == 0) { continue; }
			
			if (line[0] == PROBLEM_METADATA_LINE_INDICATOR){
				problem = handleProblemMetaData(lineNumber, line);
			} else if (line[0] == COMMENT_LINE_INDICATOR){
				continue; 
			} else {
				handleProblemLine(lineNumber, entryCnt, line, problem);
			}
		}
		
		return problem;
	}

	private Puzzle handleProblemMetaData (uint lineNumber, char[] line) {
		Puzzle problem; 

		 int counter = 0;
		 uint width, height; 
		 
		 foreach (element; delimiters!(char)(line, " "))
		 {
			 char[] s = trim(element);
			 counter++;
			 
			 switch(counter) {
				case 1: 
					// ignore the the first entry "p" that is already verified by calling this method
					break;
			 	case 2: 
					try{ 
						width = Integer.toInt(s);
						if (width <= 1) { 
							error("The WIDTH in the problem metadata line must be an integer >= 2", lineNumber, s);
						}
					} catch(IllegalArgumentException e){
						error("Could not extract the WIDTH in the problem metadata line.", lineNumber, s);
					}
					break;
				case 3: 
					try{ 
						height = Integer.toInt(s);
						if (height <= 1) { 
							error("The HEIGHT in the problem metadata line must be an integer >= 2", lineNumber, s);
						}
					} catch(IllegalArgumentException e){
						error("Could not extract the HEIGHT in the problem metadata line.", lineNumber, s);
					}
					break;
				default:
					error("Incorrect problem line: contains more entries than requested by the template 'p WIDTH HEIGHT'", lineNumber, s);
					break;
			}
		 } //foreach

		 if (counter < 3){
			 error("Incorrect problem line: contains less enties than requested by the template 'p WIDTH HEIGHT'.", lineNumber, line);
		 }
		 
		// Initialize the problem.
		problem = new Puzzle(width, height);
		
		return problem; 
	} 

	private void handleProblemLine(uint lineNumber, inout uint entryCount, char[] line, inout Puzzle problem)
	{
		uint row, column; 
		int index; 
		Symbol symbol; 
		
		foreach (element; delimiters!(char)(line, " "))
		{
			char[] s = trim!(char)(element);
			
			if( s.length == 0) { continue; }
			
			entryCount++;

			if (s[0] == '-' || s[0] == 'X' || s[0] == 'x' )
			{
				continue;
			}

			try{ 
				index = Integer.toInt(s);
				if (index > 0){
					symbol = cast(Symbol) index; 
					row = ( (entryCount - 1) / problem.numberOfColumns() ) ; 
					column = ( (entryCount - 1) % problem.numberOfColumns() ) ;
					problem.setEntry(row, column, symbol);
				}
			} catch(IllegalArgumentException e){
				error("Could not parse the element '" ~ s ~ "' in the problem line", lineNumber, line);
			}
			
		} // foreach

	} 


	/**
	 * Throws an illegal argument exception with an a specified error message and
	 * context information 
	 * Params:
	 *     msg = error message
	 *     lineNumber = (optional) number of the line of the input problem where the error occurred
	 *     processedLine = (optional) line (content) that could not be interpreted correctly  
	 */
	protected void error(char[] msg, uint lineNumber = 0, char[] processedLine = null)
	{
		
		char[] m; 
		if (lineNumber > 0){
			m ~= "[ERROR at line " ~ Integer.toString(lineNumber);
			if (processedLine !is null){
				m ~= " : '" ~ processedLine ~ "'"; 
			}
			m ~= " ] ";
		}
		m ~= msg;
		
		throw new IllegalArgumentException(m);
	}

	
} 

debug{
	import tango.io.Stdout; 
	import tango.io.device.FileConduit;
}

unittest {

	Stdout.formatln("Running unit tests of [" ~ __FILE__ ~ "]");

	auto p = new SudokuParser();
	auto file = new FileConduit("\\test\\ok-1.sdk");
	auto problem = p.parse(file.input());

	assert( problem !is null );
	assert ( problem.width() == 3 ); 
    assert ( problem.height() == 2 ); 
	assert ( problem.numberOfHints() == 0 );
	
	Stdout.formatln("PUZZLE #1");
	Stdout.formatln("\n{}\n\n", problem.toString());


	Stdout.formatln("... done!");

}