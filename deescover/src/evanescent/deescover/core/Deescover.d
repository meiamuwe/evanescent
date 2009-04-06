/**
 * <hr />
 * $(B Deescover -) 
 * A modern state-of-the-art SAT solver written in D.
 * 
 * $(P)
 * $(I Deescover is based on the MiniSat-2 (see $(LINK http://minisat.se/)) 
 * solver written in C++ by Niklas Een and Niklas Sorensson) $(BR) 
 * <hr />
 * $(P)
 * The main module for the deescover SAT solver.
 * 
 * Provides 
 * 
 * $(LI Parsing of DIMACS problem files)
 * $(LI Command line interface)
 * $(LI OS statistics for the overall process)
 * 
 * $(BR)
 * 
 * Authors: Uwe Keller
 * License: MIT
 * 
 * Version: 0.1 - April 2009, initial release
 */
module evanescent.deescover.core.Deescover;

private import evanescent.deescover.parser.dimacs.DimacsParser;
private import evanescent.deescover.core.DimacsCNFHandler;
private import evanescent.deescover.core.Solver;
private import evanescent.deescover.core.SolverTypes;

private import tango.util.ArgParser;
private import tango.io.Stdout;
private import tango.time.StopWatch;

private import tango.stdc.signal;
private import Float = tango.text.convert.Float;

private import tango.core.Runtime;
private import tango.stdc.signal;
private import tango.stdc.stdlib : exit ;

private import tango.io.model.IConduit : InputStream;
private import tango.core.Exception;
private import tango.io.stream.FileStream;

private import evanescent.deescover.core.clause.Clause;


/** The solver instance used for processing the input problem */
protected static Solver solver; 

static StopWatch* watch; 
protected static bool doExit;
protected static int errorlevel;


/**
 * Returns: the memory used by the overall process 
 * in total (in bytes)
 */
protected long memUsed(){
	return 0; //TODO: implement properly
}

void printStats(Solver solver) {
    double   cpu_time = watch.stop;
    uint 	 mem_used = memUsed();
    Stdout.format("c (re)starts        : {,19}\n", solver.starts);
    Stdout.format("c conflicts         : {,19}   ({,12:f0} /sec)\n", solver.conflicts   , solver.conflicts   /cpu_time);
    Stdout.format("c decisions         : {,19}   ({,4:f2} % random) ({,12:f0} /sec)\n", solver.decisions, cast(float)solver.rnd_decisions*100 / cast(float)solver.decisions, solver.decisions   /cpu_time);
    Stdout.format("c propagations      : {,19}   ({,12:f0} /sec)\n", solver.propagations, solver.propagations/cpu_time);
    Stdout.format("c conflict literals : {,19}   ({,4:f2} % deleted)\n", solver.tot_literals, (solver.max_literals - solver.tot_literals)*100 / cast(double)solver.max_literals);
    if (mem_used != 0) {
    	Stdout.format("c Memory used       : {,6:f2} MB\n", mem_used / 1048576.0);
    }
    Stdout.format("c CPU time          : {,19:f3} s\n", cpu_time);
}

void printUsage(char[][] args){
	Stdout.formatln(" USAGE: {} [options] -in=<input-file> \n\n  where input must be in plain DIMACS.\n", args[0]);
	Stdout.formatln(" OPTIONS:\n");
	Stdout.formatln("   -polarity-mode = {{true,false,rnd}");
	Stdout.formatln("   -decay         = <num> [ 0 - 1 ]");
	Stdout.formatln("   -rnd-freq      = <num> [ 0 - 1 ]");
	Stdout.formatln("   -verbosity     = {{0,1} ; 0 = SILENT, 1 = SOME PROGRESS INFORMATION");                                             
	Stdout.newline;
}


extern(C) {
	static void SIGINT_handler(int signum) {
		Stdout.formatln("c ");
		Stdout.formatln("c *** INTERRUPTED ***");
		printStats(solver); 
		Stdout.formatln("c *** INTERRUPTED ***");
		Stdout.formatln("c ");
		Stdout.formatln("s UNKNOWN");
		exit(1);
	}
}


public int main(char[][] args){


	if (args.length < 2) {
		printUsage(args);
		return 0;
	}	 
	
	doExit = false; 
	errorlevel = 100;
	
	watch = new StopWatch();
	
	InputStream inStream = null;

	
	bool solveProblem = true;

	
	ArgParser parser = new ArgParser();

	parser.bind("-", "h",{
		printUsage(args);
		exit(0);
	});

	parser.bind("-", "help",{
		printUsage(args);
		exit(0);
	});

	parser.bind("--", "help",{
		printUsage(args);
		exit(0);
	});


	parser.bindPosix("polarity-mode",(char[] value){
		switch (value) {
		case "true":
			solver.polarity_mode = Solver.Polarity.POLARITY_TRUE; 
			break;
		case "false":
			solver.polarity_mode = Solver.Polarity.POLARITY_FALSE;
			break;
		case "rnd":
			solver.polarity_mode = Solver.Polarity.POLARITY_RND;
			break;
		default:
			Stdout.format("ERROR! unknown polarity-mode '{}'\n", value);
		exit(0);
		}
	});

	parser.bindPosix("rnd-freq",(char[] value){
		double rnd; 
		try { 
			rnd = Float.toFloat!(char)(value);
			if (rnd < 0 || rnd > 1){
				Stdout.formatln("ERROR! illegal rnd-freq constant '{}'" , rnd);
				exit(0); 
			}

			solver.random_var_freq = rnd;

		} catch (IllegalArgumentException e){
			Stdout.format("ERROR! illegal rnd-freq constant '{}'\n", rnd);
			exit(0); 
		}

	});

	parser.bindPosix("decay",(char[] value){

		double decay; 

		try { 
			decay = Float.toFloat!(char)(value);
			if (decay < 0 || decay > 1){
				Stdout.format("ERROR! illegal decay constant '{}'\n", decay);
				exit(0); 
			}

			solver.var_decay = 1 / decay;

		} catch (IllegalArgumentException e){
			Stdout.format("ERROR! illegal decay constant '{}'\n", decay);
			exit(0); 
		}

	});

	parser.bindPosix("verbosity",(char[] value){
		switch (value) {
		case "0":
			solver.verbosity = Solver.VerbosityLevel.SILENT; 
			break;
		case "1":
			solver.verbosity = Solver.VerbosityLevel.SOME_PROGRESS_REPORT; 
			break;
		default:
			Stdout.format("ERROR! unknown verbosity constant '{}'\n", value);
		exit(0);
		}
		
	});

	parser.bindPosix("in",(char[] value){
		inStream = (new FileInput(value)).input();
	});



	solver = new Solver();
	
	parser.parse(args[1..$]);

	if (inStream is null) {
		// no input file has been specified
		printUsage(args);
		exit(0);
	}


	
	if (doExit) {
		return errorlevel;
	}

	Stdout.newline().newline();
	Stdout.format("c =============================================================================").newline();
	Stdout.format("c ========================== Deescover Version 0.1 ============================").newline();
	Stdout.format("c =============================================================================").newline();
	Stdout.formatln("c ");
	Stdout.formatln("c ");

	
	// Register some handlers for interruption and abortion of the process
	// to ensure that we still show the statistics in this case
	// e.g. when interrupting a longer solution run

	signal(SIGINT,&SIGINT_handler);
	signal(SIGTERM ,&SIGINT_handler);
	signal(SIGABRT ,&SIGINT_handler);


	
	watch.start();
	
	
	

	scope(exit) { delete solver; watch = null; }
	
	Stdout.format("c ===========================[ Problem Statistics ]============================\n");
	Stdout.format("c                                                                             |\n");

	try {
		auto problemParser = new DimacsParser();
		problemParser.parse(inStream, new DimacsCNFHandler(solver));
	
		double parsingTime =  ( watch.microsec () / 1000.f ); 
		
		Stdout.format("c   Parsing time: {,12:f2} ms \n", parsingTime);
		Stdout.format("c                                                                             |\n");
	
		if (solver.simplify() == false){
			Stdout.format("c Solved by SIMPLIFICATION only!\n");
			printStats(solver);
			Stdout.formatln("c ");
			Stdout.format("s UNSATISFIABLE\n");
			return 20;
		}

		bool ret = solver.solve();
		
		
		
		printStats(solver);
		Stdout.formatln("c ");
		Stdout.format(ret ? "s SATISFIABLE" : "s UNSATISFIABLE").newline();
		if (ret == true){
			Stdout.format("c ").newline();
			for (Var i = 1; i < solver.nVars(); i++){
				if (solver.modelValueOfVar(i) != LBool.L_UNDEF){
					Stdout.format("{}{}{}", (i==1) ? "v " : " " , (solver.modelValueOfVar(i) == LBool.L_TRUE ) ? "" : "-" , i);
				}
			}
			Stdout.formatln(" 0");
		}
		
		return (ret ? 10 : 20); 


	} catch (IllegalArgumentException e){
		Stdout.format("ERROR! Could not parse given input problem.\n");
		Stdout.format("Details:\n{} \n", e.msg);
		return 0;
	}
	
	
}


