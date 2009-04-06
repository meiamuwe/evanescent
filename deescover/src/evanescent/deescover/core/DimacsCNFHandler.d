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
 * Authors: Uwe Keller
 * License: MIT
 * 
 * Version: 0.1 - April 2009, initial release
 */
module evanescent.deescover.core.DimacsCNFHandler;

private import evanescent.deescover.util.Vec;
private import evanescent.deescover.core.SolverTypes;
private import evanescent.deescover.parser.dimacs.IDimacsHandler;
private import evanescent.deescover.parser.dimacs.AbstractDimacsHandler;
private import evanescent.deescover.core.Solver;
private import tango.io.Stdout;

/**
 * A handler for SAT problems in CNF format based
 * on the DIMACS format. 
 * 
 * Authors: Uwe Keller
 */
class DimacsCNFHandler : AbstractDimacsHandler {
	
	private Solver solver;
	
	
	/**
	 * Constructs a DimacsCNFHandler that feeds the
	 * generated clauses and variables into the given
	 * propositional solver. 
	 * 
	 * Params:
	 *     s = propositional solver that shall solve 
	 *     the input problem in DIMACS CNF 
	 */
	public this(Solver s){
		this.solver = s;
	}
	
	/**
	 * Intializes a the internal representation for a problem
	 * that has the given number of propositional variables
	 * and the given number of clauses
	 * 
	 */
	public void newProblem(uint numberOfVariables, uint numberOfClauses){
		// do nothing
	} 
	
	/**
	 * Creates an internal representation of a new clause that contains
	 * the specified literals and adds the clause to the internal
	 * representation of the problem in the solver.
	 * 
	 * Params:
	 *      literals = a list of literals of the clause
	 */
	protected void addConstraint(int[] literals){
		
		Lit lit;
		Var var; 
		
		scope Vec!(Lit) clause = new Vec!(Lit)(); 
	
		// Create the corresponding literals and add them to the clause
		foreach(int i ; literals) {
			if (i >= 0){
				var = cast(Var) i;
				lit = getLiteral(var);
			} else { 
				var = cast(Var) (-i);
				lit = getLiteral(var, false);
			}
			
			// Update the solver to represent internally enough variables 
			while (var >= solver.nVars()) {
				solver.newVar( i >= 0 , solver.nVars() > 0 );
			}
			
			clause.push(lit);
			
		}
		
						
		solver.addClause(clause);
		clause.clear();
		
	}
	
	
	
	/** 
	 * Returns: true if the format identifier is 'cnf'
	 */
	protected bool canHandleFormat(char[] format){
		return (format == "cnf");
	}
	
	
	override protected void finished(){
		Stdout.formatln("c   Input problem contains {} variables in {} clauses", solver.nVars() - 1, solver.nClauses());
	} 
	
}

