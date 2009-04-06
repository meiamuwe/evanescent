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
 * Version: 0.1 - April 2009, initial release
 */
module evanescent.deescover.core.clause.SimpleClause;

private import evanescent.deescover.core.SolverTypes;
private import evanescent.deescover.util.Vec;

/**
 * A class for representing propositional clauses.
 * 
 * Instances of the class represent in fact 
 * clause headers that contain a reference to the
 * actual literals in the clause.
 * 
 * Authors: Uwe Keller
 */

public class SimpleClause {
	
	private union ExtraInfo {
		float act;  // used only for learnt clauses to capture their activity in the solving process
		uint  abst; // used only for non-learnt (ie. problem) clauses
	}
	
	/* the members of the class */
	
	 /** number of literals in the clause along with some metadata */
	 private uint size_etc;
	 
	 private ExtraInfo extra;

	 /** A dynamic array for collecting the literals in the clause */
	 Vec!(Lit) lits; //TODO: perhaps it is better to have a pointer to the lits instead!

	
	 public this ( Lit[] ps, bool learnt = false) {
		 this( new Vec!(Lit)(ps), learnt );
	 }
	 
	 /**
	  * Creates a clause with a specified set of literals.
	  * Clauses can be marked as being learnt clauses.  
	  * 
	  * The given vector itself will not be modified or 
	  * referenced when using or modifying the clause later on.
	  * Instead the content of the vector is copied. 
	  * 
	  * Params:
	  *     ps = the set of literals the clause consists of
	  *     learnt = a boolean flag indicating if the clause is a learnt clause
	  *     if set to false or skipped, the clause is considered to be problem
	  *     clause given as input to the solver
	  */
	 public this ( Vec!(Lit) ps, bool learnt = false) {
		 lits = new Vec!(Lit)();
		 lits.growTo(ps.size(), UNDEFINED_LIT);
		 initialize(ps,learnt);
	 }
	 
	 /**
	  * (Re)initializes the clause content:  
	  * Params:
	  *     ps = the literals the clause shall contain
	  *     learnt = a boolean flag to indicate if the clause is a learnt clause
	  */
	 protected final void initialize(Vec!(Lit) ps, bool learnt) 
	 in {
		 assert( this.internalCapacity() >= ps.size() );
	 }
	 body {
		 
		 // Adapt the size the vector *without* freeing the unused memory in 
		 // the underlying container. 
		 
		 if (lits.size() < ps.size()){
			 lits.growTo(ps.size(), UNDEFINED_LIT);
		 } else {
			 lits.shrink_( lits.size() - ps.size() );
		 }
		 
		 
		 for (int i=0; i <  ps.size(); i++ ){
			 lits[i] = ps[i];
		 }
		 	 
		 // BIT STUFFING:
		 // lower 3-bits of the size_etc field contain metainformation
		 // leftmost bit == 1 iff. clause is learnt
		 size_etc = (ps.size() << 3) | cast(uint) learnt;
		 
		  // for learnt clauses initalize the activity, for others calculate
		 // the abstraction value
		 if (learnt) {
			 extra.act = 0f; 
		 } else {
			 calcAbstraction(); 
		 }
	 }
	 
	 /**
	  * Destructor for clauses, called when the clause is deleted
	  * 
	  * Frees all resources that are occupied by the clause
	  * internally.
	  */
	 public ~this(){
		 // delete lits; //FIXME: proper destruction and free list management here!
	 }
	 
	 private final void calcAbstraction() {
	        uint abstraction = 0;
	        for (int i = 0; i < this.size(); i++)
	            abstraction |= 1 << (var(lits[i]) & 31);
	        extra.abst = abstraction;  
	 }
	 
	 
	 public final int size() { 
		 // need to undo the bitstuffing
		 return size_etc >> 3;
		 // return lits.size(); //FIXME: not clear why this does not work! but the header thing odes!
	 }
	 
	 public final void shrink(int i){
		 assert(i <= size()); 
		 
		 size_etc = (((size_etc >> 3) - i) << 3) | (size_etc & 7);
		 lits.shrink(i);
	 }
	 
	 public final void pop(){
		 shrink(1); 
	 }
	 
	 public bool learnt(){ 
		 return cast(bool) (size_etc & 1); 
	 }
	 
	 public final uint mark() { 
		 return (size_etc >> 1) & 3; 
     }
	 
	 public final void mark(uint m){ 
		 size_etc = (size_etc & ~6) | ((m & 3) << 1); 
	 }
	 
	 public final Lit last() { 
		 return lits[size()-1];
	 }

	 public final int opCmp(SimpleClause other){
		 return ( this.size() - other.size() ); 
	 }
	 
	 public final Lit opIndex(uint i) {
		 return (lits[i]);
	 }

	 public final Lit opIndexAssign(Lit value, int i) {
		 lits[i] = value;
		 return value;
	 }

	 public final float activity() { 
		 return extra.act; 
	 }
	 
	 public final void setActivity(float a){
		 extra.act = a;
	 }
	 
	 public final uint abstraction() { 
		 return extra.abst; 
     }
	  
//	 /** 
//	  * Allows to iterate with foreach over all
//	  * literals in the clause
//	  */
//	 public int opApply(int delegate(inout Lit) dg) {
//		 for (int i = 0; i < size();  i++){
//			 int result = dg( lits[i] );
//			 if(result != 0){
//				 return result;  
//			 }
//		 }
//		 return 0;
//	 }

	 public char[] toString(){
		 char[] s = "{";
		 Lit l;
		 
		 for (int i = 0; i < size(); i++ ){
			 l = lits[i];
			 s ~= " "; 
			 s ~= asString( l ) ;
			 s ~= " ";
		 }
		 s ~= "}";
		 return s;
	 }
	 
	 public Lit[] literals(){
		 return lits.elements();
	 }

	 public uint internalCapacity(){
		 return lits.internalCapacity();
	 }

}


debug {
	import tango.io.Stdout;
}

unittest{
	
	Stdout("Unit Testing [SimpleClause] ... ");
	
	Lit l0 = getLiteral(0);
	Lit notl0 = getLiteral(0, false);
	
	Lit l1 = getLiteral(1);
	Lit notl1 = getLiteral(1, false);
	
	Lit l2 = getLiteral(2);
	Lit notl2 = getLiteral(2, false);
	
	Lit l3 = getLiteral(3);
	Lit notl3 = getLiteral(3, false);
	
	Lit[] lits = [l3, notl1, notl0, l2];
	IClause c = new SimpleClause(lits, false);

	assert(c.size() == 4);	
	assert(c.last() == l2);
	assert(c.learnt() == false); 
	
	assert(c[0] ==  l3);
	assert(c[1] ==  notl1);
	assert(c[2] ==  notl0);
	assert(c[3] ==  l2);
	
	Lit[] iteratedElements = []; 
	Lit l; 
	for (int i = 0; i < c.size(); i++){
		l = c[i];
		// foreach (l; c){
		iteratedElements ~= l;
	}

	assert (iteratedElements == lits);
	
	Lit[] lits2 = [l0];
	IClause c2 = new SimpleClause(lits2, true); 
	assert(c2.size() == 1);	
	assert(c2.last() == l0);
	assert(c2[0] == l0);
	assert(c2.learnt() == true); 
	
	// sanity check with references to clauses
	IClause c3 = new SimpleClause(lits, false);
	assert(c3.size() == 4);	
	
	IClause*[] pts = [];
	pts.length = 2;
	pts[0] = &c3;
	pts[1] = &c2;
	
	IClause backAgain = *pts[1];
	assert( backAgain.size() == 1);
	
	backAgain = *pts[0];
	assert( backAgain.size() == 4);
	assert(backAgain[0] ==  l3);
	assert(backAgain[1] ==  notl1);
	assert(backAgain[2] ==  notl0);
	assert(backAgain[3] ==  l2);
	
	
	// clean up clauses
	
	delete c; 
	delete c2;
	
	Stdout(" done.").newline();
}
