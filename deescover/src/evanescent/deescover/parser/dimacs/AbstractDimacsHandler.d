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
module evanescent.deescover.parser.dimacs.AbstractDimacsHandler;

private import evanescent.deescover.parser.dimacs.IDimacsHandler; 
private import Util = tango.text.Util;
private import Integer = tango.text.convert.Integer;
private import tango.core.Exception : IllegalArgumentException;


/**
 * An abstract base class for class that can interpret
 * and convert the DIMACS format for SAT problems
 * in clause normal form (CNF). 
 * 
 * Subclasses only need to take care of what to do
 * when 
 * 
 * Authors: Uwe Keller
 */
public abstract class AbstractDimacsHandler : IDimacsHandler {
	
	protected uint numberOfVariables_;
	protected uint numberOfConstraints_;
	protected char[] format_;
	
	private int[] constraintElements;
	
	
	this(){
		numberOfVariables_ = 0;
		numberOfConstraints_ = 0;
		format_ = null;
	}
	
	
	/**
	 * Define the default behaviour for comment lines: ignore comment lines
	 */
	public void handleComment(uint lineNumber, char[] line){
		// default behaviour: ignore comments
	}
	
	
	public void handleProblemMetaData(uint lineNumber, char[] line){
		
		 int counter = 0;
		 foreach (element; Util.delimiters!(char)(line, " ")){
			 char[] s = Util.trim(element);
			 counter++;
			 switch(counter) {
				case 1: 
					// ignore the the first entry "p" that is already verified by calling this method
					break;
		
			 	case 2: 
					this.format_ = s.dup;
					if (!canHandleFormat(format_)){
						error("Handler does not support the DIMACS format '" ~ format_ ~ "'", lineNumber, s);
					}
					break;
				case 3: 
					try{ 
						this.numberOfVariables_ = Integer.toInt(s);
					} catch(IllegalArgumentException e){
						this.numberOfVariables_ = 0;
						error("Could not extract the #vars in the problem metadata line.", lineNumber, s);
					}
					break;
				case 4: 
					try{ 
						this.numberOfConstraints_ = Integer.toInt(s);
					} catch(IllegalArgumentException e){
						this.numberOfConstraints_ = 0;
						error("Could not extract the #constraints in the problem metadata line.", lineNumber, s);
					}
					break;
				
				default:
					error("Incorrect problem line: contains more than 4 entries.", lineNumber, s);
					break;
			}
		 }

		 if (counter < 4){
			 error("Incorrect problem line: contains more less than 3 entries.", lineNumber, line);
		 }
		 
	
		// Initialize the problem.
		this.newProblem(this.numberOfVariables, this.numberOfConstraints);
	}
	
	
	public void handleProblemLine(uint lineNumber, char[] line){

		int counter = 0;
		constraintElements.length = 0; //TODO: to increase performance of parsing: avoid the explicit construction of the dynamic array, but use an eventbased model instead! Less GC activity!

		foreach (element; Util.delimiters!(char)(line, " ")){
			char[] s = Util.trim!(char)(element);
			counter++;

			bool isNegatedLiteral = false;
			uint indexOfPropVar;

			if (s[0] == '-') {
				isNegatedLiteral = true;
				s = s[1..$];
			}

			try{ 

				indexOfPropVar = Integer.toInt(s);
				if (indexOfPropVar == 0){
					// end delimiter of constraints in the DIMACS format 
					addConstraint(constraintElements);
					break;
				} else {
					constraintElements ~= (isNegatedLiteral ? -1 * indexOfPropVar : indexOfPropVar);
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
	protected void error(char[] msg, uint lineNumber = 0, char[] processedLine = null){
		
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
	
	
	/**
	 * Defines the default behaviour as do nothing
	 */
    public void finished(){
    	// 
    }
    
	
	public uint numberOfVariables(){
		return this.numberOfVariables_;
	}
	
	public uint numberOfConstraints(){
		return this.numberOfConstraints_;
	}
	
	public char[] format(){
		return format_;
	}
	
	
	
	
	
	/**
	 * Intializes a the internal representation for a problem
	 * that has the given number of propositional variables
	 * and the given number of constraints
	 * 
	 */
	public abstract void newProblem(uint numberOfVariables, uint numberOfConstraints);
	
	/**
	 * Creates an internal representation of a new constraint that contains
	 * the specified literals and adds the constraint to the internal
	 * representation of the problem.
	 * 
	 * Params:
	 *      elements = a list of elements of the constraint
	 */
	protected abstract void addConstraint(int[] elements);
	
	/**
	 * Checks if the given format extracted from the problem file
	 * can be handled (or interpreted) by the handler
	 * 
	 * Params:
	 *     format = format identifier as extracted from the problem file
	 * 
	 * Returns:
	 * 	   true iff. the handler can interpret the problem file encoded
	 *     in the specified format
	 */
	protected bool canHandleFormat(char[] format); 
	
	
	
}


debug {

	import tango.io.stream.FileStream;
	import tango.core.Exception;
	import tango.io.Stdout;
	import tango.time.StopWatch;
	import Integer = tango.text.convert.Integer;
	import evanescent.deescover.parser.dimacs.DimacsParser;
	

	private class DummyCNFHandler : AbstractDimacsHandler {


		public void newProblem(uint numberOfVariables, uint numberOfClauses){
		} 

		protected void addConstraint(int[] literals){
		}

		protected bool canHandleFormat(char[] format){
			return (format == "cnf");
		}

	}
}

unittest{

	Stdout("Unit Testing [AbstractDimacsHandler] ... ").newline;

	InputStream problemInput; 
	IDimacsHandler handler;
	DimacsParser parser; 

	auto watch = new StopWatch();
	double duration; 
	char[] fileLocation; 

	fileLocation = "test/sat/chnl10_11.cnf";

	Stdout("- Parsing an existing file with valid content : " ~ fileLocation);

	watch.start(); 

	parser = new DimacsParser();
	problemInput = (new FileInput(fileLocation)).input();

	handler = new DummyCNFHandler(); 
	try {
		parser.parse(problemInput, handler);
	} catch(IllegalArgumentException e){
		Stdout(e.toString()).newline;
		assert(false, "Should not throw an exception here!");
	}

	duration = watch.stop();
	Stdout.formatln(" -- Correct! Finished parsing in {,2:f3} sec", duration); 



	fileLocation = "test/sat/s3-3-3-1.cnf";

	Stdout("- Parsing an existing file with valid content : " ~ fileLocation);

	watch.start(); 

	parser = new DimacsParser();
	problemInput = (new FileInput(fileLocation)).input();

	handler = new DummyCNFHandler(); 
	try {
		parser.parse(problemInput, handler);
	} catch(IllegalArgumentException e){
		Stdout(e.toString()).newline;
		assert(false, "Should not throw an exception here!");
	}

	duration = watch.stop();
	Stdout.formatln(" -- Correct! Finished parsing in {,2:f3} sec", duration); 



	// Testing problems

	for (int i = 1; i <= 4; i++){

		fileLocation = "test/parsertest/dimacs/incorrect-dimacs-" ~ Integer.toString(i);

		Stdout("- Parsing a existing file with invalid content : " ~ fileLocation);

		watch.start(); 		

		try {
			problemInput = (new FileInput(fileLocation)).input();
			handler = new DummyCNFHandler(); 
			parser.parse(problemInput, handler);
			assert(false, "Should throw an exception here!");
		} catch(IllegalArgumentException e){
			// as expected
		} catch(Exception e2){
			assert(false, "Wrong exception throw here exception here: " ~ e2.toString());
		}

		duration = watch.stop();
		Stdout.formatln(" -- Correct! Finished parsing in {,2:f5} sec", duration); 

	}

	Stdout.newline();
	Stdout("done.").newline();
}
	