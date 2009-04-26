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
 * License: MIT
 * 
 * Version: 0.1 - April 2009, initial release 
 */
module evanescent.deescover.parser.dimacs.DimacsParser;

private import tango.io.model.IConduit : InputStream ;
private import tango.text.Util : trim;
private import evanescent.deescover.parser.dimacs.IDimacsHandler;
private import tango.text.stream.LineIterator;


/**
 * A simple parser for problem files following the
 * DIMACS format for SAT problems in clause normal form (CNF)
 */
public class DimacsParser {
	
	protected static final char COMMENT_LINE_INDICATOR = 'c';
	protected static final char PROBLEM_METADATA_LINE_INDICATOR = 'p';

	/**
	 * Parses a DIMACS problem file from an input stream and
	 * uses a DIMACS handler to interpret the problem file content.
	 * 
	 * Params:
	 *     problemData = input stream for the problem data
	 *     handler = handler to interpret and handle the single parts of the problem data
	 *     
	 * Throws: 
	 *      IllegalArgumentException if problem content can not be interpreted correctly
	 */

	public void parse(InputStream problemData, IDimacsHandler handler) {

		// Split up the input stream into lines (separated by newline symbols)
		auto lines = new LineIterator!(char) (problemData);
		scope(exit) { // ensure that the input stream is closed in any case if we leave the scope
			lines.close(); 
		}

		uint lineNumber = 0;
		while (lines.next()) {
			
			char[] line = trim!(char)(lines.get());
			
			lineNumber++;
			
			if (line.length == 0) { continue; }
			
			if (line[0] == PROBLEM_METADATA_LINE_INDICATOR){
				handler.handleProblemMetaData(lineNumber, line);
			} else if (line[0] == COMMENT_LINE_INDICATOR){
				handler.handleComment(lineNumber, line);
			} else {
				handler.handleProblemLine(lineNumber, line);
			}
		}

		handler.finished();

	}
}



debug {

	import tango.io.stream.FileStream;
	import tango.core.Exception;
	import tango.io.Stdout;
	import Integer = tango.text.convert.Integer;

	private class DummyNoProblemHandler : IDimacsHandler {

		
		public void handleProblemMetaData(uint lineNumber, char[] line){
			// do nothing
		}
		
		public void handleComment(uint lineNumber, char[] line){
			//	do nothing
		}
		
		public void handleProblemLine(uint lineNumber, char[] line){
			//  do nothing
		}
	   
	    public void finished(){
	    	//  do nothing
		}
	 
		public void newProblem(uint numberOfVariables, uint numberOfClauses){
			// do nothing
		} 

		protected void addConstraint(int[] literals){
			// do nothing
		}

		protected bool canHandleFormat(char[] format){
			return true; // any format supported
		}
		

	}
}

unittest{

	Stdout("Unit Testing [DimacsParser] ... ").newline;

	InputStream problemInput; 
	IDimacsHandler handler;
	DimacsParser parser; 

	char[] fileLocation; 

	fileLocation = "test/sat/chnl10_11.cnf";

	Stdout("- Parsing an existing file : " ~ fileLocation);

	parser = new DimacsParser();
	problemInput = (new FileInput(fileLocation)).input();

	handler = new DummyNoProblemHandler(); 
	try {
		parser.parse(problemInput, handler);
	} catch(IllegalArgumentException e){
		Stdout(e.toString()).newline;
		assert(false, "Should not throw an exception here!");
	}

	Stdout(". ok").newline; 


	// Testing problems

	fileLocation = "test/sat/non-existing-file";

	Stdout("- Parsing a non-existing file: " ~ fileLocation);

	try {
		problemInput = (new FileInput(fileLocation)).input();
		handler = new DummyNoProblemHandler(); 
		parser.parse(problemInput, handler);
		assert(false, "Should throw an exception here!");
	} catch(IOException e){
		// as expected
	}

	Stdout.formatln(" ok."); 
	Stdout("done.").newline();
}
	