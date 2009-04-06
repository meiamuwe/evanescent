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
 * 
 */
module evanescent.deescover.core.clause.Clause;

private import evanescent.deescover.core.SolverTypes;
private import evanescent.deescover.util.Vec;

private import tango.stdc.stdlib;
private import tango.core.Exception;
private import tango.core.Memory;


/**
 * A class representing propositional clauses.
 * 
 * This implementation allocates and deallocates the required memory 
 * for representing the clauses itself (ie. it is not
 * using the Garbage Collector and the Garbage Collected Heap).
 * 
 * Authors: Uwe Keller
 */


public class Clause {

	private union ExtraInfo {
		float act;  // used only for learnt clauses to capture their activity in the solving process
		uint  abst; // used only for non-learnt (ie. problem) clauses
	}
	
	 /* number of literals in the clause along with some metadata */
	 private uint size_etc;
	 
	 
	 /* some further metadata about the clause: activity and some fingerprint value*/
	 private ExtraInfo extra;
	 
	 /* 
	  * A (dynamic) array for collecting the literals in the clause 
	  * serves as a pointer to the literal array only. the array should
	  * not be managed by the GC but instead is selfmanaged. the actual size
	  * of the array is determined in the custom allocator 
	  */
	 Lit lits = void; 
	 
	 
	 // ------------------------------------------------------------------
	 //  Custom allocators and deallocators
	 // ------------------------------------------------------------------
		
	 /* 
	  * A custom allocator for clause objects:
	  * Clause objects are not managed by the garbage collector (GC) but self-managed.
	  *  
	  * Allocated enough space to represent the clause with the given number
	  * of literals (and all the other members of the class containing metadata)
	  * 
	  * The suitable constructor of this class is subsequently called to 
	  * initialize the allocated memory and construct the desired state of the object. 
	  */
	 new(size_t sz, uint numberOfLits)
	 {
		 void* p;
		 uint bytes_to_allocate = sz + ( numberOfLits ) * Lit.sizeof;
		 p =  tango.stdc.stdlib.malloc( bytes_to_allocate );
		 if (!p)
			 throw new OutOfMemoryException(__FILE__, 76);

		 // tango.core.Memory.GC.addRange(p, bytes_to_allocate); // required if we would have references in this class
		 // to objects managed by the GC
		   
		 // Stdout.formatln(" -- 0 &p = {} ", p).flush();
		 
		 return p;
	 }

	 delete(void* p)
	 {
		 if (p)
		 {   
			 // tango.core.Memory.GC.removeRange(p);  // required if we would have references in this class
			 // to objects managed by the GC
			 tango.stdc.stdlib.free(p);
		 }
	 }
	 
	 // ------------------------------------------------------------------
	 //  Constructors and Destructors
	 // ------------------------------------------------------------------
	
	 
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
		 initialize(ps,learnt);
	 }
	 
	 // ------------------------------------------------------------------
	 //  Other methods
	 // ------------------------------------------------------------------
	

	
	 /**
	  * (Re)initializes the clause content:  
	  * Params:
	  *     ps = the literals the clause shall contain
	  *     learnt = a boolean flag to indicate if the clause is a learnt clause
	  */
	 public final void initialize(Vec!(Lit) ps, bool learnt){
		 Lit* nextLit = cast(Lit*) &lits;
		 for (int i=0; i <  ps.size(); i++){ 
			 *nextLit = ps[i]; 
			 nextLit++;
		 }

		 // Some bit stuffing techniques: 
		 // lower 3-bits of the size_etc field contain metainformation
		 // leftmost bit == 1 iff. clause is learnt
		 size_etc = (ps.size() << 3) | cast(uint) learnt;

		 // for learnt clauses initalize the activity, 
		 // for others calculate the abstraction value
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
		 // do not need to do anything here directly since all
		 // relevant resources are freed in the custom class deallocator
		 // for this implementation of clause.
	 }
	 
	 private final void calcAbstraction() {
	        uint abstraction = 0;
	        Lit* nextLit = cast(Lit*) &lits;
	        for (int i = 0; i < this.size(); i++){
	        	abstraction |= 1 << (var(*nextLit) & 31);
	        	nextLit++;
	        }
	        extra.abst = abstraction;  
	 }
	 
	 
	 public final int size() { 
		 return size_etc >> 3;
	 }
	 
	 private final void setSize(uint sz){
		 size_etc = ((sz << 3) | (size_etc & 7) );
	 } 
	 
	 public final void shrink(int i)
	 in {
		 assert(i <= size()); 
	 } 
	 body {
		 size_etc = (((size_etc >> 3) - i) << 3) | (size_etc & 7);
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
		 return *( &lits + size() - 1 );
	 }

	 /**
	  * Defines < (and related operations) to compare
	  * the size of the clauses, i.e. 
	  * "this < other" iff this has less literals than other
	  * "this >= other" iff this has at least as many literals than other etc.
	  * 
	  */
	 public final int opCmp(Clause other){
		 return ( this.size() - other.size() ); 
	 }
	 
	 public final int opEquals(Object other){
		auto c = cast(Clause) other; 
		if ( c !is null
				&& size() == c.size() 
				&& learnt() == c.learnt() 
			){
			for (int i = 0; i < size(); i++){
			 if ( *(&lits + i) != c[i]){
				 	return false;
			 }
			}
			return true; 
		}
		return false;
	 }
	 
	 public final Lit opIndex(uint i) 
	 in {
		 assert( i < size() );
	 }
	 body {
		 return *( &lits + i );
	 }

	 public final Lit opIndexAssign(Lit value, int i) 
	 in {
		 assert( i < size() );
	 }
	 body {
		 *( &lits + i ) = value;
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
	  
	 public char[] toString(){
		 char[] s = "{";
		 Lit l;
		 
		 for (int i = 0; i < size(); i++ ){
			 l = this[i];
			 s ~= " "; 
			 s ~= asString( l ) ;
			 s ~= " ";
		 }
		 s ~= "}";
		 return s;
	 }
	 
	 public Lit[] literals(){
		 return ( (cast(Lit*) &lits ) [0..size()] ) ;
	 }
	 
	 public uint internalCapacity(){
		 return size();
	 }
}
	
debug {
	import tango.io.Stdout;
}

unittest{
	
	Stdout("Unit Testing [MiniSatClause] ... ");
	
	
	
	Lit l0 = getLiteral(0);
	Lit notl0 = getLiteral(0, false);
	
	Lit l1 = getLiteral(1);
	Lit notl1 = getLiteral(1, false);
	
	Lit l2 = getLiteral(2);
	Lit notl2 = getLiteral(2, false);
	
	Lit l3 = getLiteral(3);
	Lit notl3 = getLiteral(3, false);
	
	Lit[] lits = [l3, notl1, notl0, l2];
	Clause c = new(lits.length) Clause(lits, false); // IMPORTANT: with custom allocators, we can not use any interface here (IClause) otherwise, we get an access exception when calling any method!
	
	assert( c.size() == 4);	
	
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
		iteratedElements ~= l;
	}

	assert (iteratedElements == lits);
	
	Lit[] lits2 = [l0];
	Clause c2 = new(lits2.length) Clause(lits2, true); 
	assert(c2.size() == 1);	
	assert(c2.last() == l0);
	assert(c2[0] == l0);
	assert(c2.learnt() == true); 
	
	// sanity check with references to clauses
	Clause c3 = new(lits.length) Clause(lits, false);
	assert(c3.size() == 4);	
	
	Clause*[] pts = [];
	pts.length = 2;
	pts[0] = &c3;
	pts[1] = &c2;
	
	Clause backAgain = *pts[1];
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
