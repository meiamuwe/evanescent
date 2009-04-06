/**
 * <hr />
 * $(B Deescover -) 
 * A modern state-of-the-art SAT solver written in D.
 * 
 * $(P)
 * $(I Deescover is based on the MiniSat-2 (see $(LINK http://minisat.se/)) 
 * solver written in C++ by Niklas Een and Niklas Sorensson) $(BR) 
 * <hr />
 * 
 * Authors: Uwe Keller,
 *           
 * License: MIT
 * 
 * Version: 0.1 - April 2009, initial release 
 */
module evanescent.deescover.parser.dimacs.IDimacsHandler;

/**
 * An interface for classes that can interpret 
 * SAT problem files in the DIMACS format. 
 * 
 * Authors: Uwe Keller
 */


public interface IDimacsHandler {
	
	/**
	 * Called when the parser extracted a problem metadata line
	 * collecting general information about the body of the problem
	 * file, e.g. the number of variables and clauses 
	 * 
	 * Params:
	 *     lineNumber = positive integer representing the position in the 
	 *     input file from which the line has been extracted
	 *     line = the problem metadata line
	 *     
	 * Throws: IllegalArgumentException if the problem metadata can not be interpreted correctly     
	 */
	public void handleProblemMetaData(uint lineNumber, char[] line);
	
	
	/**
	 * Called when the parser extracted a comment
	 * from the problem file
	 * 
	 * Params:
	 *     lineNumber = positive integer representing the position in the 
	 *     input file from which the line has been extracted
	 *     line = the comment line
	 */
	public void handleComment(uint lineNumber, char[] line);

	/**
	 * Called when the parser extracted a problem
	 * 
	 * Params:
	 *     lineNumber = positive integer representing the position in the 
	 *     input file from which the line has been extracted
	 *     line = the comment line
	 *     
	 * Throws: IllegalArgumentException if the problem line can not be interpreted correctly
	 */
	public void handleProblemLine(uint lineNumber, char[] line);
    
    
	/**
	 * Called when the parser is finished.
	 */
    public void finished();
    
}