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
 * Various types that are commonly used in other modules of the
 * SAT solver.
 *
 * Authors: Uwe Keller 
 * 
 * License: MIT
 * 
 * Version: 0.1 - April 2009, initial release
 */
module evanescent.deescover.core.SolverTypes;

private import Integer = tango.text.convert.Integer;

debug {
	import tango.io.Stdout;
}

/**
 * A type for representing propositional variables in formulas.
 * 
 * Variables are represented simply as integer values.
 * 
 * Authors: Uwe Keller
 */
//----------------------------------------------------------
typedef int Var;
//----------------------------------------------------------


package static Var VAR_UNDEF = -1; 

/**
 * A type for representing propositional literals in formulas.
 * 
 * A literal is a positive or negative (in the logical,
 * not in the arithmetical sense) version of a 
 * propositional variable.
 * 
 * Propositional Literals are also represented as integers:
 * 
 * For a propositional variable v the index of the $(BR)
 *   - positiv literal for v is (2*v + 1) $(BR)
 *   - negative literal for v is (2*v) $(BR)
 * 
 * Authors: Uwe Keller
 */


/** A constant for denoting undefined literals */

static final Lit UNDEFINED_LIT = -2; 

//----------------------------------------------------------
typedef int Lit = -2; // Lit values are intialized automatically with the UNDEFINED_LIT value
//----------------------------------------------------------

/**
 * Create a literal for a propositional variable using
 * the specified sign
 * 
 * Params:
 *     v = propositional variable of the literal
 *     isPositive = (optional, default value is true) indicates if the literal shall be positive
 * Returns:
 * 	 the positive literal for the v if isPositive is true (or skipped), and the
 *   negative literal otherwise.
 *   
 */
public final Lit getLiteral(Var v, bool isPositive=true){
	return cast(Lit)(2 * v + cast(int) isPositive);
}

/**
 * Compute the index (or rank) of a literal
 * Params:
 *     l = a propositional literal
 * Returns:
 *     the index (or rank wrt. <) of the literal
 */
public final int index(Lit l) {
	return l;
}

/**
 * Get the propositional literal with index (or rank) i
 * Params:
 *     i = index of the requested literal wrt. <
 * Returns:
 * 	   the i-th propositional literal
 */
public final Lit litForIndex(int i) {
	return cast(Lit) i;
}

/**
 * Get the complement of a propositional literal
 * Params:
 *     l = literal to complement
 * Returns:
 * 	   the literal which is the complement of l
 */
public final Lit compl(Lit l) {
	return cast(Lit) (l ^ 1); 
}

/**
 * Get the sign of a propositional literal
 * Params:
 *     l = propositional literal
 * Returns:
 * 	   true iff. l is positive (i.e. has a positive sign)
 */

public final bool sign(Lit l){
	return cast(bool)(l & 1); 
}

/**
 * Get the propositional variable of a propositional literal
 * Params:
 *     l = a propositional literal 
 * Returns:
 * 	   the propositional variable of l
 */
public final Var var(Lit l){
	return cast(Var)(l >> 1);
}

/**
 * Get the positive variant of the literal
 * Params:
 *     l = a propositional literal
 * Returns:
 *     the positive variant of l, i.e. not(j) if l = j and
 *     j if l = not(j) for some j
 */
public final Lit unsign(Lit l){
	return cast(Lit)(l | 1);
} 

public char[] asString(Lit l){
	return Integer.toString(l);
}

	


unittest{ 

	Stdout("Unit Testing [Literal Functionality] ... ");
	Var v1 = 1;
	Var v2 = 5;
	
	Lit p = getLiteral(v1, true); 
	Lit notp = getLiteral(v1, false);

	assert(p != notp);
	assert(p == p);
	assert(p != UNDEFINED_LIT);

	Lit anotherp = getLiteral(v1);
	Lit q = getLiteral(v2);
	Lit notq = getLiteral(v2, false);
	
	assert(p != q);
	assert(anotherp == p);

	// ordering of literals

	assert (p !< p); 
	assert (p == p); 
	assert (p < notp || notp < p);
	assert (p < q);
	assert (notp < q);

	// check helper methods
	
 	assert (litForIndex(index(p)) == p);
 	assert (litForIndex(index(notp)) == notp);
	
 	assert (compl(p) == notp);
	assert (compl(notp) == p);
	assert (compl(q) == notq);
	assert (compl(notq) == q);
	
	
	assert (var(p) ==  v1);
	assert (var(notp) ==  v1);
	assert (var(q) ==  v2);
	
	assert (getLiteral(var(q), false) == compl(q) );
	
	assert (sign(p) is true);
	assert (sign(notp) is false);
	
	assert (unsign(q) ==  q);
	assert (unsign(notp) ==  p);
	
	
	
	
	 	
	Stdout(" done.").newline();

}

//----------------------------------------------------------

/**
 * A type for lifted booleans, i.e. the boolean values true
 * and false extended with undefined
 */

//----------------------------------------------------------
public enum LBool: byte { 
	L_TRUE = 1, 
	L_FALSE = -1 , 
	L_UNDEF = 0
}
// ----------------------------------------------------------

public final bool toBool(LBool b){
	return (b == LBool.L_TRUE ? true : false );
}

public final LBool compl(LBool b){
	return cast(LBool)(-b);
}


unittest{
	Stdout("Unit Testing [LBool auxilliary functions] ... ");
	//TODO: insert unit tests here
	assert (toBool(LBool.L_TRUE) == true);
	assert (toBool(LBool.L_FALSE) == false);
	assert (toBool(LBool.L_UNDEF) == false);
	
	assert (compl(LBool.L_TRUE) == LBool.L_FALSE );
	assert (compl(LBool.L_FALSE) == LBool.L_TRUE);
	assert (compl(LBool.L_UNDEF) == LBool.L_UNDEF);
	
	
	Stdout(" done.").newline();
}



