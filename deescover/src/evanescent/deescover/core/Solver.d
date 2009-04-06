/**
 * <hr />
 * $(B Deescover -) 
 * A modern state-of-the-art SAT solver written in D.
 * 
 * $(I Deescover is based on the MiniSat-2 (see $(LINK http://minisat.se/)) 
 * solver written in C++ by Niklas Een and Niklas Sorensson) $(BR) 
 * <hr />
 * 
 * The implementation represents a modern conflict-driven DPLL-style 
 * decision procedure for the satisfiability of propositional formulae.
 * 
 * The solver provides the following features:
 * 
 * $(LI DPLL-style backtracking search)
 * $(LI Conflict-directed search: VSIDS branching heuristic)
 * $(LI Clause learning)
 * $(LI Conflict clause minimization)
 * $(LI Restarts)
 * 
 * $(BR)
 * Further, the implementation provides support for $(B incremental SAT solving)
 * which can speed up applications that need to solve series of 
 * related (or similar) SAT problems, e.g. SAT-based model checking algorithms.
 * 
 * $(BR)
 * Authors: Uwe Keller
 * 
 * License: MIT
 * 
 * Version: 0.1 - April 2009, initial release
 */
module evanescent.deescover.core.Solver;


private import evanescent.deescover.core.SolverTypes;
private import evanescent.deescover.util.Vec;
private import evanescent.deescover.util.Sort;
private import evanescent.deescover.util.Heap;
private import tango.math.Math;
private import tango.io.Stdout;
private import evanescent.deescover.core.clause.Clause;


class Solver {

	// If problem is satisfiable, this vector contains the model (if any)
    protected Vec!(LBool) model;    
    
    // If problem is unsatisfiable (possibly under assumptions),
	// this vector represent the final conflict clause expressed in the assumptions.
    protected Vec!(Lit) conflict;      	

    
    //  Mode of operation:
    
    //  Inverse of the variable activity decay factor. (default 1 / 0.95)
    double    var_decay;          
    //  Inverse of the clause activity decay factor. (1 / 0.999)
    double    clause_decay;       
    //  The frequency with which the decision heuristic tries to choose a random variable. (default 0.02)
    double    random_var_freq;    
    //  The initial restart limit. (default 100) 
    int       restart_first;
    //  The factor with which the restart limit is multiplied in each restart. (default 1.5)
    double    restart_inc;       
    //  The intitial limit for learnt clauses is a factor of the original clauses. (default 1 / 3)
    double    learntsize_factor;  
    //  The limit for learnt clauses is multiplied with this factor each restart. (default 1.1)
    double    learntsize_inc;     

    //  Controls conflict clause minimization. (default TRUE)
    bool      expensive_ccmin;    
    
    //  Controls which polarity the decision heuristic chooses. 
    // 	See enum below for allowed modes. (default polarity_false)
    Polarity  polarity_mode = Polarity.POLARITY_FALSE; 
    //  Verbosity level. 0=silent, 1=some progress report (default 0)
    VerbosityLevel  verbosity;          

    public enum Polarity : byte {
    	/** select positive literal when branching on a variable */
    	POLARITY_TRUE = 0, 	
    	/** select negative literal when branching on a variable */
    	POLARITY_FALSE = 1, 
    	/** select literal variant as specified by the user when branching on a variable */
    	POLARITY_USER = 2,  
    	/** select literal variant randomly when branching on a variable */
    	POLARITY_RND = 3 	
    };
    
    public enum VerbosityLevel : byte {
    	SILENT = 0, 
    	SOME_PROGRESS_REPORT = 1
    }
    
    // Statistics: (read-only member variable)
    
    ulong starts, decisions, rnd_decisions, propagations, conflicts;
    ulong clauses_literals, learnts_literals, max_literals, tot_literals;

    // Solver state:
   
    protected bool            	ok;               // If FALSE, the constraints are already unsatisfiable. No part of the solver state may be used!
    protected Vec!(Clause)    	clauses;          // List of problem clauses. 
    protected Vec!(Clause)    	learnts;          // List of learnt clauses. 
    protected double          	cla_inc;          // Amount to bump next clause with.
    protected Vec!(double)    	activity;         // A heuristic measurement of the activity of a variable.
    protected double          	var_inc;          // Amount to bump next variable with.
    protected Vec!(Vec!(Clause)) watches;          // 'watches[lit]' is a list of constraints watching 'lit' (will go there if literal becomes true).
    protected Vec!(LBool)       assigns;          // The current assignments (lbool:s stored as char:s).
    protected Vec!(Polarity)    polarity;         // The preferred polarity of each variable.
    protected Vec!(bool)        decision_var;     // Declares if a variable is eligible for selection in the decision heuristic.
    protected Vec!(Lit)         trail;            // Assignment stack; stores all assigments made in the order they were made.
    protected Vec!(int)         trail_lim;        // Separator indices for different decision levels in 'trail'.
    protected Vec!(Clause)     	reason;           // 'reason[var]' is the clause that implied the variables current value, or 'NULL' if none.
    
    protected Vec!(uint)        level;            // 'level[var]' contains the level at which the assignment was made.
    protected int             	qhead;            // Head of queue (as index into the trail -- no more explicit propagation queue in MiniSat).
    protected int             	simpDB_assigns;   // Number of top-level assignments since last execution of 'simplify()'.
    protected ulong           	simpDB_props;     // Remaining number of propagations that must be made before next execution of 'simplify()'.
    
    protected Vec!(Lit)         assumptions;      // Current set of assumptions provided to solve by the user.
    protected Heap        		order_heap;       // A priority queue of variables ordered with respect to the variable activity.
    
    protected double            random_seed;      // Used by the random variable selection.
    protected double            progress_estimate;// Set by 'search()'.
    protected bool              remove_satisfied; // Indicates whether possibly inefficient linear scan for satisfied clauses should be performed in 'simplify'.

    // Temporaries (to reduce allocation overhead). Each variable is prefixed by the method in which it is
    // used, exept 'seen' wich is used in several places.
    //
    private Vec!(bool)       	 seen; 
    private Vec!(Lit)            analyze_stack;
    private Vec!(Lit)            analyze_toclear;
    private Vec!(Lit)            add_tmp;

   
    // --------------------------------------------------------------
    // -- Some auxilliary methods for branching decision ordering
    // --------------------------------------------------------------
    
    // dynamic VSIDS-style ordering 
    
    /**
     * Check if a propositional variable x is currently more active 
     * than another propositional variable y
     */
    protected final bool moreActiveThan(int x, int y) {
		return activity[x] > activity[y];
	}
    
    // static syntax-based ordering (depends on the order in which variables are created by the solver 
    // (and hence on the var numbering produced by an application using this SAT solver) 
    
    /**
     * Check if a propositional variable x is currently more active 
     * than another propositional variable y
     */
    protected final bool hasLargerIndexThan(int x, int y) {
		return x > y;
	}
    
    // --------------------------------------------------------------
    // -- Some minor methods
    // --------------------------------------------------------------
   
    protected final void insertVarOrder(Var x) {
        if (!order_heap.inHeap(x) && decision_var[x]) {
        	order_heap.insert(x); 
        }
    }
    
    protected final void varDecayActivity() { 
    	var_inc *= var_decay; 
    }

    protected final void varBumpActivity(Var v) {
    	activity[v] = activity[v] + var_inc;
    	if ( activity[v] > 1e100 ) {
    		// Rescale:
    		for (int i = 0; i < nVars(); i++){
    			activity[i] = activity[i] * 1e-100;
    		}
    		var_inc *= 1e-100; 
    	}

    	// Update order_heap with respect to new activity:
    	if (order_heap.inHeap(v)){
    		order_heap.decrease(v);
    	}
    }
    
    protected final void claDecayActivity() { 
    	cla_inc *= clause_decay; 
    }
    
    protected final void claBumpActivity (inout Clause c) {
    	float updatedClauseActivity = c.activity();
    	updatedClauseActivity += cla_inc;
    	c.setActivity(updatedClauseActivity);
    	
    	if ( updatedClauseActivity > 1e20 ) { 
    		// Rescale:
    		Clause lc; 
    		for (int i = 0; i < learnts.size(); i++){
    			lc = learnts[i];
    			updatedClauseActivity = lc.activity();
    			updatedClauseActivity *= 1e-20;
    			c.setActivity(updatedClauseActivity);
    		}
    		cla_inc *= 1e-20; 
    	} 
    }

    /**
     * Assume that a specific literal is true with the given reason.
     * 
     * Params:
     *     p = a propositional literal that 
     *     reason = the reason for the assumption (the unit clause that forced)
     * Returns:
     * 		false if a conflict has been detected by assuming p
     * 		as being true and true if no conflict arises from assiging
     * 		p the truth value true. 
     */
    protected final bool enqueue(Lit p, Clause reason){ 
    	if (value(p) != LBool.L_UNDEF) {
    		return (value(p) == LBool.L_FALSE);
    	} else { 
    		uncheckedEnqueue(p, reason); 
    		return true; 
    	}
    }
    
    /**
     * Checks if a (learnt) clause is locked, i.e. 
     * if it is currently the reason for an assigned literal
     * which can still play a role in conflict analysis. 
     * 
     * Locked clauses must therefore not be deleted when
     * reducing the clause database.
     * 
     * The method should only be called for learnt clauses
     * 
     * Params:
     *     c = the learnt clause to be checked
     * Returns:
     * 	   true if the given learnt clause is locked and hence still plays
     * 	   a role for conflict analysis
     */
    protected final bool locked (Clause c)
    in { 	
    	assert ( c.learnt() ); 
    }
    body
    { 
    	return (reason[var(c[0])] is c && value(c[0]) == LBool.L_TRUE);
    }
    
    protected final void newDecisionLevel(){ 
    	trail_lim.push(trail.size()); 
    }

    protected final uint decisionLevel(){ 
    	return trail_lim.size();
    }
    
    protected final uint abstractLevel(Var x) {
    	// Hashing / Fingerprinting function: 
    	// Produces a unsigned int value (4 byte length) 
    	// with a single 1 bit (flag) that represents
    	// the lowest 5 bits of the decision level
    	// for the given variable (which make up
    	// a value between 0 and 31, hence a valid
    	// index for the bitshift within an integer
    	return 1 << (level[x] & 31); 
    }
    
    
    protected final LBool valueOfVar (Var x) { 
    	return assigns[x]; 
    }
    
    protected final LBool value(Lit p){
    	return (sign(p) ? assigns[var(p)] : compl(assigns[var(p)]) ); 
    }
    
    public final LBool modelValue(Lit p){ 
    	return (sign(p) ? model[var(p)] : compl(model[var(p)]) ); 
    }
    
    public final LBool modelValueOfVar (Var x) { 
    	return model[x]; 
    }
    
    public final int nAssigns() { 
    	return trail.size(); 
    }
    
    public final int nClauses() { 
    	return clauses.size() ;
    }
    
    public final int nLearnts() { 
    	return learnts.size(); 
    }
    
    public final int nVars() { 
    	return assigns.size(); 
    }
    
    
    /**
     * A method to enable users to selectivly influence or
     * define the branching behaviour of the solver for 
     * distinct propositional variables. 
     * 
     * Declares which truth assignment for a propositional
     * variable should be investigated by the solver first,
     * when the variable is selected for branching.
     * 
     * Params:
     *     v = a propositional variable
     *     b = if true (false) , the positive (negative) literal for v is used first
     *     when branching on v
     */
    public final void setPolarity(Var v, bool b) { 
    	if (b) {
    		polarity[v] = Polarity.POLARITY_TRUE;
    	} else {
    		polarity[v] = Polarity.POLARITY_FALSE;
    	}
    }
    
    /**
     * Declares a variable to be considered as a decision
     * variable during the search process. This means
     * that the variable can be branched upon. For non-decision
     * variables, the solver will not branch on truth assignments
     * for these variables, their truth value will only be inferred. 
     * 
     * Params:
     *     v = a propositional variable to be declared as a decision or a 
     *     non-decision variable to the solver
     *     b = if set to true, v is considered as a decision variable, if 
     *     set to false v is non considered as a decision variable (and excluded
     *     from the branching process as a decision point)
     */
    public final void setDecisionVar(Var v, bool b) { 
    	decision_var[v] = b; 
    	if (b) { 
    		insertVarOrder(v); 
    	} 
    }
    
    /**
     * Starts the solver on the input problem loaded into the solver
     * before. 
     * 
     * The solver does not use any assumptions on truth values for variables
     * of the problem (besides what can be inferred from the problem in
     * an obvious way)  
     * 
     * If the solver returns true (ie. the input problem is satisfiable) the
     * respective model can be inspected with calls to 
     * modelValueOfVar(Var v)
     *  
     * Returns: true iff the formula is satisfiable
     */
    public final bool solve() {  
    	return solve( new Vec!(Lit)() ); 
    }
    

    
    // --------------------------------------------------------------
    // -- Some auxilliary methods 
    // --------------------------------------------------------------
    
    // Returns a random float 0 <= x < 1. Seed must never be 0.
    static final double drand(inout double seed)
    in {
    	assert(seed != 0);
    }
    body {
        seed *= 1389796;
        int q = cast(int)(seed / 2147483647);
        seed -= cast(double)q * 2147483647;
        return seed / 2147483647; 
     }

    // Returns a random integer 0 <= x < size. Seed must never be 0.
    static final int irand(inout double seed, int size)
    in {
    	assert(seed != 0);
    }
    body {
        return cast(int)(drand(seed) * size); 
    }
    
    
    // --------------------------------------------------------------
    // -- Main part of the solver: constructor and destructor
    // --------------------------------------------------------------
    
    /** 
     * Solver intialization. 
     * 
     * This implementation provides support for incremental SAT solving.
     * Hence, the solver instance can be reused to solve a series
     * of related problems, while sharing some information between 
     * subsequent solving processes of these related problems (ie.
     * learnt clauses) 
     */
    public this(){
    	
    	var_decay = 1 / 0.95;
    	clause_decay = 1 / 0.999; 
    	random_var_freq = 0.02;

    	restart_first = 100; 
    	restart_inc = 1.5;

    	learntsize_factor = cast(double)1/cast(double)3; 
    	learntsize_inc = 1.1; 

    	expensive_ccmin = true;
    	polarity_mode = Polarity.POLARITY_FALSE;
    	verbosity = VerbosityLevel.SILENT; 


    	// Statistics
    	starts = 0;
    	decisions = 0; 

    	rnd_decisions = 0; 
    	propagations = 0;  
    	conflicts = 0;
    	clauses_literals = 0;
    	learnts_literals = 0;
    	max_literals = 0;
    	tot_literals = 0;


    	ok = true;

    	cla_inc = 1;
    	var_inc = 1;
    	qhead = 0;

    	simpDB_assigns = -1;
    	simpDB_props = 0;

    	
    	random_seed = 91648253; // ensures repeatability
    	progress_estimate = 0;
    	remove_satisfied = true;
    	
    	clauses = new Vec!(Clause)(); 
        learnts  = new Vec!(Clause)(); 
        
        activity = new Vec!(double)();
        
        watches = new Vec!(Vec!(Clause))();
        assigns = new Vec!(LBool)();
        
        polarity = new Vec!(Polarity);
        decision_var = new Vec!(bool);
        trail = new  Vec!(Lit)(); 
        trail_lim = new Vec!(int)();
        
        reason = new Vec!(Clause)();
        level = new Vec!(uint)();
        assumptions = new Vec!(Lit)();
        
        seen = new Vec!(bool); 
        analyze_stack = new Vec!(Lit)();
        analyze_toclear = new Vec!(Lit)();
        add_tmp = new Vec!(Lit)();
        
        model = new Vec!(LBool)();
        conflict = new  Vec!(Lit)();
        
        // represent and maintain the variable order for branching on a heap
        // use an dynamic activity based variable order: VSIDS-style 
        
        order_heap =  new Heap( &this.moreActiveThan ); // VSIDS-style heuristic
        
        
    }

    
    
    /**
     * Destructor to free all allocated resources, in particular
     * the problem clauses and learnt clauses
     */
    public ~this() { 
    	
    	// Empty watcher lists (without removing the clauses contained)
    	uint watches_size =  watches.size();
    	for (int i=0; i < watches_size; i++){
    		watches[i].clear(false);
    	}
    	watches.clear(false);
    	
    	// Now actually remove all known clauses 
    	learnts.clear(true);
    	clauses.clear(true);
    }
    
    
    // --------------------------------------------------------------
    // -- Main part of the solver: minor methods
    // --------------------------------------------------------------
    
/**  
 * Creates a new propositional variable which can be used
 * by clients to construct propositional problems to be processed
 * by the solver instance. 
 * 
 * Params:
 *   pol = (optional, default=false) a boolean flag indicating the which literal variant shall
 *   be considered first when branching on the variable. 
 *   If set to true (false), then the positive (negative) literal for that variable 
 *   will be prefered in a branching step
 *   
 *   dvar = (optional, default=true) a boolean flag indicating if the 
 *   created variable shall be considered as a decision variable during
 *   the search process (i.e. the solver is allowed to branch on the
 *   truth value assignment for that variable during the search process) 
 *   
 * $(P)
 * $(B Note:) if 'dvar' is false, the variable will not be used as a decision variable 
 * This has effects on the meaning of an UNSATISFIABLE result:
 * If the solver returns unsatisfiable, then this means that the solver could
 * not construct any model for the input problem by avoiding to branch on
 * the variables that have been declared as non-decision variables by the client
 */
 public Var newVar(bool pol = false, bool dvar = true)
 {
     Var v = cast(Var) nVars();
     watches.push( new Vec!(Clause)() );          // (list for positive literal)
     watches.push( new Vec!(Clause)() );          // (list for negative literal)
     reason.push(null);
     assigns.push(LBool.L_UNDEF);
     level.push(-1);
     activity.push(0.0);
     seen.push(false);
     
     polarity.push(pol ? Polarity.POLARITY_TRUE : Polarity.POLARITY_FALSE); 
     decision_var.push(dvar);
    
     insertVarOrder(v);

     return v;
 }

 

/**
 * Add a clause to the solver and potentially simplify the clause
 * wrt the current clause database.
 * 
 * Params:
 * 		ps = a vector of literals the clause shall consist of
 * 
 * Returns: true, if the clause has been processed and the problem
 * is not yet detected as being unsatisfiable. false, if the problem
 * is detected as being unsatisfiable, hence the solver does not need 
 * to be started at all.
 * 
 */
 public bool addClause(Vec!(Lit) ps)
 {
	 debug {
     	// Logout.trace.format("\n--- Adding Clause : ps = {}" , ps.elements());
	 }
	 
     assert(decisionLevel() == 0); 

     if (!ok) { 
    	 // can happen, if we already know that previously 
    	 // added clauses are unsatisfiable
         return false;
     } else {
         // Check if clause is satisfied and remove false/duplicate literals:
    	 
    	 // sort to detect all duplicate literals in the clause in a single pass
         ps.sort(); 
         
         Lit p; 
         int i, j;
         
         for (i = j = 0, p = UNDEFINED_LIT; i < ps.size(); i++){
             if (value(ps[i]) == LBool.L_TRUE ||  ps[i] == compl(p)){
            	 // clause is satisfied under the current assignment 
                 return true;
             } else if (value(ps[i]) != LBool.L_FALSE && ps[i] != p){
                 ps[j++] = p = ps[i];
             } 
         }
         
         ps.shrink(i - j);
         
     }
    
     if (ps.size() == 0) {
         return ok = false; 
     } else if (ps.size() == 1){ 
    	 // after simplification we end up with a unit clause: 
    	 // Deterministic inference: assign the variable of the clause accordingly
         assert(value(ps[0]) == LBool.L_UNDEF); // since the literal has not been simplified away, it must be undefined 
         uncheckedEnqueue(ps[0], null);
         return ok = (propagate() is null); // no conflict detected by deterministic inference
     } else {
         Clause c = new(ps.size()) Clause(ps, false);
         clauses.push(c);
         attachClause(c); // set watched literals for the clause and update statistics
     }
     
     return true;
 }

 
 protected void attachClause(inout Clause c) 
 in {
	 assert(c.size() > 1);
 } 
 body {

	 // invariant: the first two literals in clause with size >=2 are watched
	 watches[index(compl(c[0]))].push(c);
	 watches[index(compl(c[1]))].push(c);
	 
	 if (c.learnt()) { 
    	 learnts_literals += c.size();
     } else {          
    	 clauses_literals += c.size(); 
     }
 }
 
 
/**
 * Release the clause from all internal data structures
 * (such as watch lists) of the solver that affect the
 * search process.
 * 
 * After the call no reference to the clause can exist anymore
 * which might affect the search.
 * 
 * Prepares for the deletion of the clause (but does not delete the
 * clause) 
 * 
 * Params:
 *     c = clause to be released (and later on deleted)
 */ 
protected void detachClause(inout Clause c) 
in {
    assert( c.size() > 1 );
   	assert( watches[index(compl(c[0]))].find(c) == true );
    assert( watches[index(compl(c[1]))].find(c) == true );
} 
body {

	if (c.learnt()) {
		learnts_literals -= c.size();
	}
	else {
		clauses_literals -= c.size(); 
	}

	watches[index(compl(c[0]))].remove(c); 
	watches[index(compl(c[1]))].remove(c);
    
}
 
 /**
  * Removes a clause from the clause database. 
  * Important: this method may not be called in an
  * uncontrolled manner during the search. 
  * 
  * Params:
  *     c = a clause to be deleted from the clause
  *     database (and memory)
  */
 public void removeClause(inout Clause c) {
	 detachClause(c); // note: object c may not be deleted already during this call
     delete c; 
 }


/**
 * Check if the given clause is satisfied wrt. the current 
 * truth value assignments.
 * 
 * Params:
 *     c = a propositional clause
 * Returns:
 *  	true iff. the clause is satisfied wrt. the current truth
 *   	value assignments to propositional literals by the solver
 */
 public final bool satisfied(inout Clause c) {
	 auto c_size = c.size();
	 for (int i = 0; i < c_size; i++)
		 if (value(c[i]) == LBool.L_TRUE){
			 return true;
		 }
	 return false; 
}
 

/**
 * Revert to the state at given level
 * keeping all assignment at 'level' but not beyond.
 */
 protected final void cancelUntil(int level) {
	 
	 debug {
	    	// Stdout.format("\n--- Enter cancelUntil() ").flush();
	 }
	 if (decisionLevel() > level){
		 
		 
		 debug {
		     	// Stdout.format("\n---> BACKTRACKING from decision level {} to decision level {}" , decisionLevel(), level);
		 }
		 
		 for (int c = trail.size()-1; c >= trail_lim[level]; c--){
			 Var     x  = var(trail[c]);
			 assigns[x] = LBool.L_UNDEF;
			 insertVarOrder(x); 
		 }
		 qhead = trail_lim[level];
		 trail.shrink_(trail.size() - trail_lim[level]);
		 trail_lim.shrink_(trail_lim.size() - level);
		 
		 
	 } 
	 debug {
	    	// Stdout.format("\n--- Leave cancelUntil() ").flush();
	 }
 }


 // --------------------------------------------------------------
 // -- Main part of the solver: major methods
 // --------------------------------------------------------------

/**
 * Selects the next literal to branch on
 * 
 * Params:
 *     polarity_mode = polarity mode to be used for the literal selection  
 *     
 *     $(P 
 *     
 *     	$(LI POLARITY_TRUE means that the positive literal is selected first)
 *     	$(LI POLARITY_FALSE means that the  negative literal is selected first)
 *      $(LI POLARITY_RND means the sign of the selected literal is chosen at random)
 *      $(LI POLARITY_USR means the sign is selected as specified in the 
 *          			 POLARITY vector for the selected literal)
 *      )
 *      
 *     random_var_freq = real value between between 0 and 1 indicating the probability
 *     of a random selection of the next literal to branch on 
 *     
 * Returns:
 * 		the literal to consider in the next branching step first or 
 * 		L_UNDEF if no literal could be selected for branching (i.e.
 * 		there are no unassigned variables left, or all unassigned variables
 *      are specified to be non-branching variables for the solver)
 */
package Lit pickBranchLit(int polarity_mode, double random_var_freq){
    Var next = VAR_UNDEF;

//    debug {
//		Stdout.format("\n-- Enter pickBranchLit() ").flush;
//	}
    // Random decision:
    if (drand(random_seed) < random_var_freq && !order_heap.empty()){
    	next = cast(Var) order_heap[irand(random_seed,order_heap.size())];
    	
    	// Check if the randomly picked literal is (1) not assigned a truth value yet
    	// and (2) can be considered for branching 
    	if (assigns[next] == LBool.L_UNDEF && decision_var[next]){  // TODO: this means that random_var_freq does not indicate that a random decision is really taken (if heap is non-empty!) Introduce a loop here!
    		rnd_decisions++; 
    	}
    }
  
    // If no random decision is taken, then use an activity based heuristic   

    // Activity based decision:
    while (next == VAR_UNDEF || assigns[next] != LBool.L_UNDEF || !decision_var[next]){
    	if (order_heap.empty()){
    		next = VAR_UNDEF;
    		break;
    	} else {
    		next =  cast(Var) order_heap.removeMin(); 
    	}
    }
    
    bool sign = false;
    
    switch (polarity_mode){
    	case Polarity.POLARITY_TRUE:  sign = true; break;
    	case Polarity.POLARITY_FALSE: sign = false;  break;
    	case Polarity.POLARITY_USER:  sign = ( polarity[next] == Polarity.POLARITY_TRUE ); break; //TODO: allow as well to user_defined random?
    	case Polarity.POLARITY_RND:   sign = cast(bool) irand(random_seed, 2); break;
    	
    	default: assert(false); 
    }

//    debug {
//		Stdout.format("\n-- Leave pickBranchLit() ").flush;
//	}
    
    return (next == VAR_UNDEF ? UNDEFINED_LIT : getLiteral(next, sign));
}


/**
 * Analyze conflict and produce a reason clause.
 *  
 * Params:
 *     confl = the clause that is known to be unsatisfied by the current assignment (after a call to propagate())
 *     out_learnt = a container to collect the literals for the costructed learnt clause
 *     out_btlevel = the decision level to which we backtrack (in general non-chronological!)
 * 
 * Preconditions: 
 * $(LI 'out_learnt' is assumed to be cleared )
 * $(LI Current decision level must be greater than root level)
 * 
 * Postconditions: 
 * $(LI 'out_learnt[0]' is the asserting literal at level 'out_btlevel')
 * 
 * Effect:
 * 	Will undo part of the trail, upto but not beyond the assumption of the current 
 *  decision level.
 */
package void analyze(in Clause confl, inout Vec!(Lit) out_learnt, inout int out_btlevel)
in {
	assert( out_learnt !is null);
	assert( out_learnt.size() == 0 );
	
}
body {
	int pathC = 0;
	Lit p     = UNDEFINED_LIT;

	debug {
		// Stdout.format("\n--- Enter analyze()").flush();
	}	

	// Generate conflict clause:
	//
	out_learnt.push();      // (leave room for the asserting literal)
	int index   = trail.size() - 1;
	out_btlevel = 0;

	do {

		assert(confl !is null && confl.size() > 0);          // (otherwise should be UIP)
		Clause c = confl;

		if (c.learnt()){
			claBumpActivity(c); // every learnt clause which participates in a conflict is "active" and hence bumped
		} 

		auto c_size = c.size();
		for (int j = ( p == UNDEFINED_LIT ? 0 : 1) ; j < c_size; j++){
			Lit q = c[j];

			if (!seen[var(q)] && level[var(q)] > 0){ 
				// variable for the current literal is not seen yet and 
				// was not set on the root level (assumption or immediate consequence of assumptions)

				varBumpActivity(var(q)); // variable is participating in a conflict and hence active. Therefore bump the activity
				seen[var(q)] = true;	     // mark variable as seen

				if (level[var(q)] >= decisionLevel()){
					pathC++;
				} else {
					out_learnt.push(q); 		// compute the 1-UIP here
					if (level[var(q)] > out_btlevel){ 
						out_btlevel = level[var(q)]; // set backtracking to maximal decision level of literals in conflict clauses that is smaller than the current decision level
					}
				}
			}
		}


		// Select next clause to look at:
		while (!seen[var(trail[index--])]){
			//move-backward in assignment history
		}

		p     = trail[index+1];
		confl = reason[var(p)];
		seen[var(p)] = false;
		pathC--;

	} while (pathC > 0);
	out_learnt[0] = compl(p);

	// Simplify conflict clause:
	int i, j;
	if (expensive_ccmin) {

		uint abstract_level = 0;
		auto ol_size = out_learnt.size();
		for (i = 1; i < ol_size; i++){
			abstract_level |= abstractLevel(var(out_learnt[i])); // (maintain an abstraction of levels involved in conflict)
		}

		out_learnt.copyTo(analyze_toclear);
		for (i = j = 1; i < ol_size; i++){
			if (reason[var(out_learnt[i])] is null 
					|| !litRedundant(out_learnt[i], abstract_level)){
				out_learnt[j++] = out_learnt[i];
			}
		}
	} else {
		out_learnt.copyTo(analyze_toclear);
		auto ol_size = out_learnt.size();
		for (i = j = 1; i < ol_size; i++){
			Clause c = reason[var(out_learnt[i])];
			auto c_size = c.size();
			for (int k = 1; k < c_size; k++){
				auto v = var(c[k]); 
				if (!seen[v] && level[v] > 0){
					out_learnt[j++] = out_learnt[i];
					break; 
				}
			}
		}
	}
    
    max_literals += out_learnt.size(); // update: maximally required #lits in conflict clauses
    out_learnt.shrink(i - j);	       // Reduce the computed conflict clause
    tot_literals += out_learnt.size(); // update: actually required #lits in conflict clauses (due to minimization)

    
    // Find correct backtrack level:
    //
    if (out_learnt.size() == 1) {
        out_btlevel = 0;
    } else {
    	
        int max_i = 1;
        auto ol_size = out_learnt.size();
        for (i = 2; i < ol_size; i++){
            if (level[var(out_learnt[i])] > level[var(out_learnt[max_i])])
                max_i = i;
        }
        
        // For performance enhancement: 
        // ensure that the first literal in the learnt conflict clause is the one which is going to be flipped
        // next after backtracking
        p             = out_learnt[max_i];
        out_learnt[max_i] = out_learnt[1];
        out_learnt[1]     = p;
        out_btlevel       = level[var(p)];
    }

    auto atc_size = analyze_toclear.size();
    for (j = 0; j < atc_size; j++) {
    	seen[var(analyze_toclear[j])] = false;    // ('seen[]' is now cleared)
    }
    
    debug {
    	// Stdout.format("\n--- Leave analyze() ").flush();
    }	
}



/**
 * Check if 'p' can be removed from a clause. The clause is not 
 * used itself in the test, but represented by an abstraction 
 * (a fingerprint value abstract_levels representing the relevant information
 * needed for the test)
 * 
 * 'abstract_levels' is used to abort early if the algorithm is
 * visiting literals at levels that cannot be removed later.
 */
protected bool litRedundant(Lit p, uint abstract_levels) {
	analyze_stack.clear(); 
	analyze_stack.push(p);
	int top = analyze_toclear.size();

	while (analyze_stack.size() > 0){
		assert( reason[var(analyze_stack.last())] !is null );

		Clause c = reason[var(analyze_stack.last())]; 
		analyze_stack.pop();

		for (int i = 1; i < c.size(); i++){
			p  = c[i];
			if (!seen[var(p)] && level[var(p)] > 0){
				if (reason[var(p)] !is null && (abstractLevel(var(p)) & abstract_levels) != 0){
					seen[var(p)] = true;
					analyze_stack.push(p);
					analyze_toclear.push(p);
				} else {
					for (int j = top; j < analyze_toclear.size(); j++){
						seen[var(analyze_toclear[j])] = false;
					}
					analyze_toclear.shrink_(analyze_toclear.size() - top);
					return false;
				}
			}
		}
	}

	return true;
}

/**
 *  Specialized analysis procedure to express the final conflict in terms of assumptions.
 *    Calculates the (possibly empty) set of assumptions that led to the assignment of 'p', and
 *   stores the result in 'out_conflict'.
 *   
 * Params:
 *     p = the literal which caused the last conflict
 *     out_conflict = a learnt clause representing which assumptions caused literal p to
 *     be assigned true
 */
package void analyzeFinal(Lit p, inout Vec!(Lit) out_conflict) {
	
	debug {
    	// Stdout.format("\n--- Enter analyzeFinal () ").flush();
    }	
	
	out_conflict.clear();
    out_conflict.push(p);

    if (decisionLevel() == 0)
        return;

    seen[var(p)] = true;

    for (int i = trail.size()-1; i >= trail_lim[0]; i--){
        Var x = var(trail[i]);
        if (seen[x]){
            if (reason[x] is null){
                assert(level[x] > 0);
                out_conflict.push(compl(trail[i]));
            } else {
                Clause c = reason[x];
                for (int j = 1; j < c.size(); j++){
                    if (level[var(c[j])] > 0){
                        seen[var(c[j])] = true;
                    }
                }
            }
            seen[x] = false;
        }
    }

    seen[var(p)] = false;
    
    debug {
    	// Stdout.format("\n--- Leave analyzeFinal() ").flush();
    }	
}

/**
 * Assigns a truth value at the current decision level such that
 * the literal p is satisfied (or true) and records clause from
 * as the reason for that decision. f
 * 
 * Params:
 *     p = literal to satisfy
 *     from = reason for that decision
 */
protected void uncheckedEnqueue(Lit p, Clause from = null) {
    assert(value(p) == LBool.L_UNDEF);
    
    assigns [var(p)] = (sign(p) ? LBool.L_TRUE : LBool.L_FALSE); 
    level   [var(p)] = decisionLevel();
    reason  [var(p)] = from;
    trail.push(p);
}

/**
 * Performs exhaustively all deterministic inferences that can be computed in 
 * the current search state.
 * 
 * What can be inferred from the currenst search state depends on the 
 * deterministic inference system which is considered and implemented. 
 * 
 * The deterministic inference rules supported by this implementation 
 * is the standard one for DPLL-style SAT solvers and consists of   
 * $(B Unit Propagation) only.
 * 
 * 
 * Returns: If a conflict arises, the conflicting clause is returned, otherwise null.
 */
package final Clause propagate() {
    Clause confl     = null;
    int     num_props = 0;
    
    
    // Stdout.format("\n--------------- Enter: Propagate()").flush();
    
    while (qhead < trail.size()){
        Lit            p   = trail[qhead++];     // 'p' is enqueued fact to propagate.
        Vec!(Clause) ws  =  watches[index(p)];
        int i, j, end;
        
        debug {
         	// Stdout.format("\n--------------- Propagating literal {} with truth value {}" , p, value(p) ).flush();
        }

        num_props++;

        Clause c;
        Lit false_lit;
        Lit first_lit;
        
        for (i = j = 0, end = i + ws.size();  i != end;){
        	c = ws[i++];
        	 	
        	assert( c.size() >= 2 ); 
        	
            // Make sure the false literal is c[1]:
            false_lit = compl(p);
            if (c[0] == false_lit){
                c[0] = c[1], c[1] = false_lit;
            }
            
            assert(c[1] == false_lit);

            first_lit = c[0];
            if (value(first_lit) == LBool.L_TRUE){
            	 // If watch c[0] is true, then clause is already satisfied.
                ws[j++] = c; 
                
            } else {
            	// Clause is not yet obviously satisifed by looking at the watches
            	// First literal c[0] of the clause now must be either UNDEF or FALSE
                // Look for new watch:
            	auto c_size = c.size(); 
                for (int k = 2; k < c_size; k++)
                	// literals that are either UNDEF or TRUE can be selected as watches
                    if (value(c[k]) != LBool.L_FALSE){ 
                    	// switch the newly selected watch literal with the one assigned FALSE c[1]
                        c[1] = c[k], c[k] = false_lit;
                        watches[index(compl(c[1]))].push(c); // add the clause to the watch list for the newly selected watch literal
            
                        goto FoundWatch; // note: for these clauses (non-unit and UNDEF) no increase of j happens
                        	// this means: they are going to be deleted from the watch list of p (since p is set and now no longer watched!)
                       
                    }
           
                // Did not find watch --
                // All other literals besides the first watch c[0] are false
                // Hence: clause is unit under assignment or a conflict clause (and not satisifed yet)
                
                ws[j++] = c;
                if (value(first_lit) == LBool.L_FALSE){ // clause is indeed unsat: have a conflict clause
                
                	confl = c;
                    qhead = trail.size(); // Move propqueue head to end of trail: take all desired lit assignments (and their reasons) into account when analyzing a conflict
                    // Copy the remaining clauses in the watched list (such that they do not get lost):
                    while (i < end){
                        ws[j++] = ws[i++];
                    }
                } else { // for unit clauses we need to enqueue the single non-assigned literal to true
                    uncheckedEnqueue(first_lit, c); // enqueue the first watched literal for unit propagation
                }
            }
        FoundWatch:;
        } // foreach watched clause of the propagated literal p
        
        ws.shrink(i - j); // remove all clauses for which p is no longer watched (has been replaced by some other literal)
    }
    propagations += num_props;
    simpDB_props -= num_props;

    // Stdout.format("\n--------------- Leave: Propagate()");
    
    return confl;
}

/**
 * Reduces the kept pool of learnt clauses. 
 * 
 * Remove half of the learnt clauses, minus the clauses locked by the current assignment. 
 * Locked clauses are clauses that are reason to some assignment. 
 * Binary clauses are never removed.
 * Further: remove all non-binary and non-locked clauses which have too little acticity
 */

package final void reduceDB() {
    
	debug 
	{
    	// Stdout.format("\n--- Enter reduceDB() ").flush();
    }	
	
	int     i, j;
    double  extra_lim = cla_inc / learnts.size();    // Remove any clause below this activity

    
    learnts.sort(&reduceDB_clause_order_lessThan); // sort learnt clauses according to 
    
    Clause c;
    // Consider the 50% of the learnt clauses which are least wrt the order used for sorting
    for (i = j = 0; i < ((learnts.size() / 2)  ); i++){
    	c = learnts[i];
        if (c.size() > 2 && !locked(c) ){
            removeClause(c);
        } else { 
        	// binary clauses and locked clauses are never deleted in a simplification step
        	learnts[j++] = c;
        }
    }
    
    // Also remove from the remaining learnt clauses each clause with too little activity
    for (; i < learnts.size(); i++){
    	c = learnts[i];
    	if (c.size() > 2 && !locked(c) && c.activity() < extra_lim){
    		removeClause(c);
    	} else {
    		learnts[j++] = c;
    	}
    }
    	
    learnts.shrink_(i - j); // shrink the learnt clauses vector accordingly
     	
    
    debug 
    {
    	// Stdout.format("\n--- Leave reduceDB() ").flush();
    }	
}


package void removeSatisfied(inout Vec!(Clause) cs){
    int i,j;
    Clause c;
    for (i = j = 0; i < cs.size(); i++){
    	c = cs[i];
        if (satisfied(c)){
            removeClause(c);
        } else {
            cs[j++] = c;
        }
    }
    cs.shrink_(i - j);
}

/**
 * Simplify the clause database according to the current top-level assigment. 
 * 
 * Currently, the only thing done here is the removal of satisfied clauses, 
 * but more things can be put here.
 * 
 * Returns: false if the solver is in an undefined (unusable) state or the input problem
 *  		 has been determined as unsatisfiable after simplification (hence no actual search is needed)
 */
public final bool simplify()
{
	debug {
    	// Stdout.format("\n--- Enter simplify() ").flush();
    }	
	assert(decisionLevel() == 0);

    if (!ok || propagate() !is null){
        return ok = false;
    }

    if (nAssigns() == simpDB_assigns || (simpDB_props > 0)){ // no new assignments have been made on the progate() call
        return true;
    }

    // Remove satisfied clauses:
    removeSatisfied(learnts);
    if (remove_satisfied) {       // Can be turned off.
        removeSatisfied(clauses);
    }

    // Remove fixed variables from the variable heap:
    // order_heap.filter(VarFilter(this));
    order_heap.filter( 
    	(int v){ // v is unassigned and is allowed to be used as a decision var
    		return (cast(bool) (this.assigns[v] == LBool.L_UNDEF) && this.decision_var[v]); 
    	} 
    );

    simpDB_assigns = nAssigns();
    simpDB_props   = clauses_literals + learnts_literals;   // (shouldn't depend on stats really, but it will do for now)

    debug {
    	// Stdout.format("\n--- Leave simplify() ").flush();
    }	
    
    return true;
}

/**
 * Search for a model the specified number of conflicts, keeping the number of learnt clauses
 *    below the provided limit. 
 *    
 * $(B Note:) Use negative value for 'nof_conflicts' or 'nof_learnts' to indicate infinity.
 * 
 * Params:
 *     nof_conflicts = an upper-bound on the number of conflicts that are allowed to appear 
 *     within the search process
 *     nof_learnts = an upper-bound on the number of clauses that are allowed to be learnt 
 *     within the search process
 *     
 * Returns:
 * 	'L_TRUE' if a partial assigment that is consistent with respect to the clauseset is found. 
 *  If all variables are decision variables, this means that the clause set is satisfiable. 
 *  'L_FALSE' if the clause set is unsatisfiable. 
 *  'L_UNDEF' if the bound on number of conflicts has been reached and neither satisfiability nor
 *  unsatisfiability could be shown (within the allowed number of conflicts)
 */
package final LBool search(int nof_conflicts, int nof_learnts) {
	
	debug {
    	// Stdout.format("\n--- Starting search: ").flush();
	}
	
	assert(ok); // only run the solver if the internal state is valid
    
    int         backtrack_level;
    int         conflictC = 0;
    scope Vec!(Lit)  learnt_clause = new Vec!(Lit)(); // scope attribute means that the vector is allocated 
    	// in the stack (not the heap) and that 
    	// the vector object will be destructed as soon as the object goes out of scope
   
    starts++;

    bool first = true;

    for (;;){
        Clause confl = propagate();
       
        if (confl !is null){
        	
        	assert( confl.size() > 0 );
        	
            // CONFLICT
            conflicts++; 
            conflictC++;
            if (decisionLevel() == 0) { 
            	// conflict at decision level 0 means we have an unsatisfiable problem
            	return LBool.L_FALSE;
            }

            first = false;

            learnt_clause.clear(); 
            
            
            analyze(confl, learnt_clause, backtrack_level); 
            cancelUntil(backtrack_level);
            
            assert(value(learnt_clause[0]) == LBool.L_UNDEF); // first literal in the learnt conflict clause is the one to be flipped right after backtracking (UIP property!)

            if (learnt_clause.size() == 1){
                uncheckedEnqueue(learnt_clause[0], null); // the only literal learnt_clause[0] in the learnt clause is implied and hence like a decision (hence: null reason)
            } else {
                Clause c = new(learnt_clause.size()) Clause(learnt_clause, true);  
                learnts.push(c);
                attachClause(c); // set up watchers and so on
                claBumpActivity(c); // clause has been learned and therefore is considered as active
                uncheckedEnqueue(learnt_clause[0], c); // because of construction of learnt clause and UIP, learnt_clause[0] must true (backjumping to case: lit learnt_clause[0] holds case )
            }

            // After each conflict, we decay both, the variable and the clause activities
            varDecayActivity();
            claDecayActivity();

        } else {
            // NO CONFLICT
        	
            if (nof_conflicts >= 0 && conflictC >= nof_conflicts){
                // Reached bound on number of conflicts:
                progress_estimate = progressEstimate();
                // reset the assignments and assignment history of the solver (but keep learnt clauses)
                cancelUntil(0);
                return LBool.L_UNDEF; 
            }

            
            // Simplify the set of problem clauses:
            if (decisionLevel() == 0 && !simplify()){ // TODO: Shouldn't this be: dLevel() == assumps.size()
                return LBool.L_FALSE;
            }            
            
           
            if (nof_learnts >= 0 && learnts.size() - nAssigns() >= nof_learnts) {
                // Reduce the set of learnt clauses:
                reduceDB();
            }
           
            Lit next = UNDEFINED_LIT;
            
            while (decisionLevel() < assumptions.size()){ 
            	// Perform user provided assumption:
                Lit p = assumptions[decisionLevel()];
                if (value(p) == LBool.L_TRUE){
                    // Dummy decision level:
                    newDecisionLevel();
                } else if (value(p) == LBool.L_FALSE) {
                    analyzeFinal(compl(p), conflict); 
                    return LBool.L_FALSE;
                } else {
                    next = p;
                    break;
                }
            }
         
            if (next == UNDEFINED_LIT){
                // New variable decision:
                decisions++;
                next = pickBranchLit(polarity_mode, random_var_freq);

                if (next == UNDEFINED_LIT){
                    // Model found:
                    return LBool.L_TRUE;
                }
            }
      
            // Increase decision level and enqueue 'next'
            assert(value(next) == LBool.L_UNDEF);
            
            debug {
            	// Stdout.format("\n-------> Branching on: literal={} : variable {}, {}", next, var(next), (sign(next) ? "positive case" : "negative case" ) ).flush();
            }
            
            newDecisionLevel();
            uncheckedEnqueue(next);
         }
    }
    
    debug {
    	// Stdout.format("\n--- Finished search run.");
    }
    
}

package final real progressEstimate() {
    double  progress = 0;
    real  F = 1.0 / nVars();

    for (int i = 0; i <= decisionLevel(); i++){
        int beg = (i == 0 ? 0 : trail_lim[i - 1]);
        int end = (i == decisionLevel() ? trail.size() : trail_lim[i]);
        progress += tango.math.Math.pow(F, i) * (end - beg);
    }

    return progress / nVars();
}


public final bool solve(Vec!(Lit) assumps) {
	
    model.clear();
    conflict.clear();

    if (!ok) return false;

    assumps.copyTo(assumptions);
    
    assert( assumps.size() == assumptions.size() );
    
    double  nof_conflicts = restart_first;
    double  nof_learnts   = nClauses() * learntsize_factor;
    LBool   status        = LBool.L_UNDEF;

    if (verbosity >= 1){
        Stdout.format("c ==========================[ Search Statistics ]==============================\n").flush();
        Stdout.format("c Conflicts |          ORIGINAL         |          LEARNT          | Progress |\n").flush();
        Stdout.format("c           |    Vars  Clauses Literals |    Limit  Clauses Lit/Cl |          |\n").flush();
        Stdout.format("c =============================================================================\n").flush();
    }
    

    // Search:
    while (status == LBool.L_UNDEF){
        if (verbosity > VerbosityLevel.SILENT ){
        	Stdout.formatln("c {,9} | {,7} {,8} {,8} | {,8} {,8} {,6:f0} | {,6:f3} % |", 
        		conflicts, order_heap.size(), nClauses(), clauses_literals, nof_learnts, 
        		nLearnts(), cast(double)learnts_literals/nLearnts(), progress_estimate*100); 
        }
        status = search(cast(int) nof_conflicts, cast(int)nof_learnts);
    
        nof_conflicts *= restart_inc;
        nof_learnts   *= learntsize_inc;
    }

    if (verbosity >= 1)
    	Stdout.format("c =============================================================================\n");

    
    if (status == LBool.L_TRUE){
    	// Extend & copy model:
    	model.growTo(nVars());
    	for (Var i = 0; i < nVars(); i++) {
    		model[i] = valueOfVar(i); 
    	}

    	debug {
    		verifyModel();
    	}
    	 
    } else {
    	assert(status == LBool.L_FALSE);
    	if (conflict.size() == 0){
    		ok = false;
    	}
    }

    // Reset the internal state of the solver (assingments) but keep the learnt clauses!
    // Keeping the learnt clauses is important for speeding up subsequent searches
    // on related problems in a series when clients need incremental SAT solving
    cancelUntil(0); 
    return (status == LBool.L_TRUE);
}

/**
 * If the solve() method returns true, then this method can be used to retrieve
 * the computed satisfying interpretation for the input problem. 
 * 
 * Returns: a model for the input clauses (under the given assumptions), if solve() 
 * has been called on the input problem before and returned true.
 */
public Vec!(LBool) getModel(){
	return model; 
}

// --------------------------------------------------------------
// -- Debug methods
// --------------------------------------------------------------


protected final void verifyModel()
{
	bool failed = false;
	int i;
	Clause c;

	for (i = 0; i < clauses.size(); i++){
		assert(clauses[i].mark() == 0); 
		c = clauses[i];
		for (int j = 0; j < c.size(); j++){
			if (modelValue(c[j]) == LBool.L_TRUE){
				goto next;
			}
		}

		failed = true;
		next: ;
	}

	assert(!failed, "Computed interpretation is not a model for the input problem!" );
}

} // class Solver


/**
 * Defines the order for reduction of learnt clauses:
 * 
 * - Never remove binary clauses
 * - Remove clauses with (currently) least activity
 * 
 * The least ones wrt this order will be removed.
 * Note: unary clauses are never represented explicity!
 */
private bool reduceDB_clause_order_lessThan(Clause x, Clause y){
	return (x.size() > 2 && (y.size() == 2 || x.activity() < y.activity() )); 
}




unittest {
	Stdout("Unit Testing [Solver] ... ").newline;

	Solver s; 
	bool satisfiable; 
	bool notDetectedAsUnsat;
	int NUM_VARS;
	
	Stdout("- Testing simplest satisfiable problem: negative unit clause  ").flush();
	
	s = new Solver(); 
	
	// Create NUM_VARS variables and literals
	NUM_VARS = 1; 
	Var[] v = new Var[NUM_VARS];
	for (int i = 0; i < NUM_VARS ; i++){
		v[i] = s.newVar();
	}
	Lit[] poslit = new Lit[NUM_VARS];
	Lit[] neglit = new Lit[NUM_VARS];
	for (int i = 0; i < NUM_VARS ; i++){
		poslit[i] = getLiteral(v[i]); 
		neglit[i] = getLiteral(v[i],false); 
	}
	
	
	notDetectedAsUnsat =
				s.addClause( new Vec!(Lit)( [ neglit[0] ] ) );
	
	
	if (notDetectedAsUnsat){
		satisfiable = s.solve();
	} else {
		satisfiable = false; 
	}
	
	assert ( satisfiable == true ); 
	
	Stdout.formatln("Found model :" ).flush();
	for (int i = 0; i < s.nVars(); i++){
		Stdout.formatln("\t{} : {}", i, toBool(s.model[i]) ).flush();
	}
	
	Stdout(" ").newline;
	
	Stdout("ok.\n").newline;
	
	
	
	Stdout("- Testing simplest satisfiable problem: positive unit clause  ").flush();
	
	s = new Solver(); 
	
	// Create NUM_VARS variables and literals
	NUM_VARS = 1; 
	v = new Var[NUM_VARS];
	for (int i = 0; i < NUM_VARS ; i++){
		v[i] = s.newVar();
	}
	poslit = new Lit[NUM_VARS];
	neglit = new Lit[NUM_VARS];
	for (int i = 0; i < NUM_VARS ; i++){
		poslit[i] = getLiteral(v[i]); 
		neglit[i] = getLiteral(v[i],false); 
	}
	
	
	notDetectedAsUnsat =
				s.addClause( new Vec!(Lit)( [ poslit[0] ] ) );
	
	
	if (notDetectedAsUnsat){
		satisfiable = s.solve();
	} else {
		satisfiable = false; 
	}
	
	assert ( satisfiable == true ); 
	
	Stdout.formatln("Found model :" ).flush();
	for (int i = 0; i < s.nVars(); i++){
		Stdout.formatln("\t{} : {}", i, toBool(s.model[i]) ).flush();
	}
	
	Stdout(" ").newline;
	
	Stdout("ok.\n").newline;
	
	
	
	
	
	
	Stdout("- Testing simplest satisfiable problem: binary clause ").flush();
	
	s = new Solver(); 
	
	// Create NUM_VARS variables and literals
	NUM_VARS = 2; 
	v = new Var[NUM_VARS];
	for (int i = 0; i < NUM_VARS ; i++){
		v[i] = s.newVar();
	}
	poslit = new Lit[NUM_VARS];
	neglit = new Lit[NUM_VARS];
	for (int i = 0; i < NUM_VARS ; i++){
		poslit[i] = getLiteral(v[i]); 
		neglit[i] = getLiteral(v[i],false); 
	}
		
	notDetectedAsUnsat =
				s.addClause( new Vec!(Lit)( [ poslit[0], poslit[1] ] ) );
	
	
	if (notDetectedAsUnsat){
		satisfiable = s.solve();
	} else {
		satisfiable = false; 
	}
	
	assert ( satisfiable == true ); 
	
	Stdout.formatln("Found model :" ).flush();
	for (int i = 0; i < s.nVars(); i++){
		Stdout.formatln("\t{} : {}", i, toBool(s.model[i]) ).flush();
	}
	
	Stdout(" ").newline;
	
	Stdout(" ok.").newline;
	
    s = new Solver(); 
	
	// Create NUM_VARS variables and literals
	NUM_VARS = 2; 
	v = new Var[NUM_VARS];
	for (int i = 0; i < NUM_VARS ; i++){
		v[i] = s.newVar();
	}
	poslit = new Lit[NUM_VARS];
	neglit = new Lit[NUM_VARS];
	for (int i = 0; i < NUM_VARS ; i++){
		poslit[i] = getLiteral(v[i]); 
		neglit[i] = getLiteral(v[i],false); 
	}
	
	
	notDetectedAsUnsat =
				s.addClause( new Vec!(Lit)( [ neglit[0], neglit[1] ] ) );
	
	
	if (notDetectedAsUnsat){
		satisfiable = s.solve();
	} else {
		satisfiable = false; 
	}
	
	assert ( satisfiable == true ); 
	
	Stdout.formatln("Found model :" ).flush();
	for (int i = 0; i < s.nVars(); i++){
		Stdout.formatln("\t{} : {}", i, toBool(s.model[i]) ).flush();
	}
	
	Stdout(" ").newline;
	
	Stdout(" ok.").newline;
	
	
	
	s = new Solver(); 
	
	// Create NUM_VARS variables and literals
	NUM_VARS = 2; 
	v = new Var[NUM_VARS];
	for (int i = 0; i < NUM_VARS ; i++){
		v[i] = s.newVar();
	}
	poslit = new Lit[NUM_VARS];
	neglit = new Lit[NUM_VARS];
	for (int i = 0; i < NUM_VARS ; i++){
		poslit[i] = getLiteral(v[i]); 
		neglit[i] = getLiteral(v[i],false); 
	}
		
	notDetectedAsUnsat =
				s.addClause( new Vec!(Lit)( [ neglit[1], poslit[1] ] ) );
	
	
	if (notDetectedAsUnsat){
		satisfiable = s.solve();
	} else {
		satisfiable = false; 
	}
	
	assert ( satisfiable == true ); 
	
	Stdout.formatln("Found model :" ).flush();
	for (int i = 0; i < s.nVars(); i++){
		Stdout.formatln("\t{} : {}", i, toBool(s.model[i]) ).flush();
	}
	
	Stdout(" ").newline;
	
	Stdout(" ok.").newline;
	
	
	Stdout("- Testing a simple satisfiable problem: multiple binary clauses ");
	
	s = new Solver(); 

	
	// Create NUM_VARS variables and literals
	NUM_VARS = 6; 
	v = new Var[NUM_VARS];
	for (int i = 0; i < NUM_VARS ; i++){
		v[i] = s.newVar();
	}
	poslit = new Lit[NUM_VARS];
	neglit = new Lit[NUM_VARS];
	for (int i = 0; i < NUM_VARS ; i++){
		poslit[i] = getLiteral(v[i]); 
		neglit[i] = getLiteral(v[i],false); 
	}
	
	notDetectedAsUnsat =
				s.addClause( new Vec!(Lit)( [poslit[0]] ) ) 
			&& 	s.addClause( new Vec!(Lit)( [neglit[0],poslit[1]]) )
			&& 	s.addClause( new Vec!(Lit)( [neglit[1],neglit[2]]) ) 
			&& 	s.addClause( new Vec!(Lit)( [neglit[1],poslit[3]]) ) 
			&& 	s.addClause( new Vec!(Lit)( [poslit[5],neglit[4]]) ) ;
			// && 	s.addClause( new Vec!(Lit)( [-1, -4, 5, -6]) );
	
	if (notDetectedAsUnsat){
		satisfiable = s.solve();
	} else {
		satisfiable = false; 
	}
	assert ( satisfiable == true ); 
	
	Stdout.formatln("Found model :" );
	for (int i = 0; i < s.nVars(); i++){
		Stdout.formatln("\t{} : {}", i, toBool(s.model[i]) );
	}
	
	Stdout(" ").newline;
	
	Stdout(" ok.").newline;
	
	
	Stdout("- Testing simplest satisfiable problem: 3-ary clause ").flush();
	
	s = new Solver(); 

	// Create NUM_VARS variables and literals
	NUM_VARS = 3; 
	v = new Var[NUM_VARS];
	for (int i = 0; i < NUM_VARS ; i++){
		v[i] = s.newVar();
	}
	poslit = new Lit[NUM_VARS];
	neglit = new Lit[NUM_VARS];
	for (int i = 0; i < NUM_VARS ; i++){
		poslit[i] = getLiteral(v[i]); 
		neglit[i] = getLiteral(v[i],false); 
	}

	notDetectedAsUnsat =
		s.addClause( new Vec!(Lit)( [ poslit[0], neglit[1], neglit[0] ] ) );


	if (notDetectedAsUnsat){
		satisfiable = s.solve();
	} else {
		satisfiable = false; 
	}

	assert ( satisfiable == true ); 
	
	Stdout.formatln("Found model :" );
	for (int i = 0; i < s.nVars(); i++){
		Stdout.formatln("\t{} : {}", i, toBool(s.model[i]) );
	}
	
	Stdout(" ").newline;
	
	Stdout(" ok.").newline;
	

	
	Stdout("- Testing simplest satisfiable problem: 4-ary clause ").flush();
	
	s = new Solver(); 
	
	// Create NUM_VARS variables and literals
	NUM_VARS = 4; 
	v = new Var[NUM_VARS];
	for (int i = 0; i < NUM_VARS ; i++){
		v[i] = s.newVar();
	}
	poslit = new Lit[NUM_VARS];
	neglit = new Lit[NUM_VARS];
	for (int i = 0; i < NUM_VARS ; i++){
		poslit[i] = getLiteral(v[i]); 
		neglit[i] = getLiteral(v[i],false); 
	}
		
	notDetectedAsUnsat =
				s.addClause( new Vec!(Lit)( [ poslit[0], neglit[1], neglit[2], poslit[3] ] ) );
	
	
	if (notDetectedAsUnsat){
		satisfiable = s.solve();
	} else {
		satisfiable = false; 
	}
	
	assert ( satisfiable == true ); 
	
	Stdout.formatln("Found model :" );
	for (int i = 0; i < s.nVars(); i++){
		Stdout.formatln("\t{} : {}", i, toBool(s.model[i]) );
	}
	
	Stdout(" ").newline;
	
	Stdout(" ok.").newline;
	
	
	Stdout("- Testing a simple satisfiable problem: multiple n-ary clauses ");
	
	s = new Solver(); 

	
	// Create NUM_VARS variables and literals
	NUM_VARS = 6; 
	v = new Var[NUM_VARS];
	for (int i = 0; i < NUM_VARS ; i++){
		v[i] = s.newVar();
	}
	poslit = new Lit[NUM_VARS];
	neglit = new Lit[NUM_VARS];
	for (int i = 0; i < NUM_VARS ; i++){
		poslit[i] = getLiteral(v[i]); 
		neglit[i] = getLiteral(v[i],false); 
	}
	
	notDetectedAsUnsat =
				s.addClause( new Vec!(Lit)( [poslit[0]] ) ) 
			&& 	s.addClause( new Vec!(Lit)( [neglit[0],poslit[1]]) )
			&& 	s.addClause( new Vec!(Lit)( [neglit[1],neglit[2]]) ) 
			&& 	s.addClause( new Vec!(Lit)( [neglit[1],poslit[3]]) ) 
			&& 	s.addClause( new Vec!(Lit)( [poslit[5],neglit[4]]) ) 
			&& 	s.addClause( new Vec!(Lit)( [poslit[2], neglit[3], neglit[1], neglit[5], neglit[4]]) ) ;
	
	if (notDetectedAsUnsat){
		satisfiable = s.solve();
	} else {
		satisfiable = false; 
	}
	assert ( satisfiable == true ); 
	
	Stdout.formatln("Found model :" );
	for (int i = 0; i < s.nVars(); i++){
		Stdout.formatln("\t{} : {}", i, toBool(s.model[i]) );
	}
	
	Stdout(" ").newline;
	
	Stdout(" ok.").newline;
	
	// Testing simple unsat cases

	Stdout("- Testing a simple unsatisfiable problem: mutliple 2-ary clauses");
	
	s = new Solver(); 

	
	// Create NUM_VARS variables and literals
	NUM_VARS = 6; 
	v = new Var[NUM_VARS];
	for (int i = 0; i < NUM_VARS ; i++){
		v[i] = s.newVar();
	}
	poslit = new Lit[NUM_VARS];
	neglit = new Lit[NUM_VARS];
	for (int i = 0; i < NUM_VARS ; i++){
		poslit[i] = getLiteral(v[i]); 
		neglit[i] = getLiteral(v[i],false); 
	}
	
	notDetectedAsUnsat =
				s.addClause( new Vec!(Lit)( [poslit[0]] ) ) 
			&& 	s.addClause( new Vec!(Lit)( [neglit[0],poslit[1]]) )
			&& 	s.addClause( new Vec!(Lit)( [neglit[1],neglit[2]]) ) 
			&& 	s.addClause( new Vec!(Lit)( [neglit[1],poslit[3]]) ) 
			&& 	s.addClause( new Vec!(Lit)( [poslit[5],neglit[4]]) ) 
			&& 	s.addClause( new Vec!(Lit)( [poslit[2], neglit[3]]) ) ;
	
	if (notDetectedAsUnsat){
		satisfiable = s.solve();
	} else {
		satisfiable = false; 
	}
	assert ( satisfiable == false ); 
		
	
	Stdout(" ").newline;
	
	Stdout(" ok.").newline;
	
	
	
	
	Stdout.newline();
	Stdout("done.").newline();
	
}
