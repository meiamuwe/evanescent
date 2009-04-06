
module RunBenchmarkProblems; 

private import  tango.io.Stdout,
                tango.io.FileScan,
                Integer = tango.text.convert.Integer, 
                tango.time.StopWatch,
                tango.io.File,
                tango.io.FilePath,
                tango.text.Text,
                tango.core.Exception,
                tango.sys.Process;

/*******************************************************************************

        Run a DIMACS based SAT solver on all ".cnf" files visible via a 
        directory given as a command-line argument. 
        
*******************************************************************************/

public void printUsage(char[][] args)
{
   Stdout("\nUSAGE: ").newline();
   Stdout.formatln("{} <solver-call-command> <repeat-cnt> <dir> <output-file>", args[0]);
   Stdout.formatln("where: ");
   Stdout.formatln("  <solver-call-command> is a string that can be used for invokinga DIMACS-based SAT solver from the command line.");
   Stdout.formatln("  The command should contain '$(file)' as a place holder for the benchmark file name the solver shall work on");
   Stdout.formatln("  <repeat-cnt> is a positive integer indicating how often to invoke the solver on each problem file.");
   Stdout.formatln("  <dir> is the path to a directory containing benchmark problem instances in DIMACS CNF format (file suffix '.cnf').");
   Stdout.formatln("  <output-file> is the name of the output file where the results are logged.").newline();
   
   Stdout("EXAMPLE: ").newline;
   Stdout.formatln("{} \"Deescover -verbosity=1 -in=$(file) -decay=0.998\" 10 test\\unsat benchmark-unsat-1.results", args[0]);
   Stdout.formatln("	invokes the Deescover solver (with specifed parameter settings) on each problem file (with suffix '.cnf')");
   Stdout.formatln("    from directory 'test\\unsat' 10 times and logs the results for each run and each problem file in 'benchmark-unsat-1.results'.");
   
}

void solveProblem(FilePath f, in uint repeats, char[] cmdTemplate, File dst )
{
	auto cmd = new Text!(char)(cmdTemplate);  
	if (cmd.select("$(file)")){
		cmd.replace(f.toString()); 
	}
	 
	for (int i = 1; i <= repeats && invoke(cmd.slice(), f.toString(), i, dst); i++) {
		Stdout("#").flush(); // some progress bar 
	}
}

bool invoke(char[] startUpSolverCmd, char[] problem, uint cnt, File dst)
{

	scope watch = StopWatch();
	
	try {
    	auto p = new Process(startUpSolverCmd, null);
    	
    	watch.start();
    	p.execute();

		auto result = p.wait();
		auto cpu_time = watch.stop(); // in seconds
		
		char[] satisfiabilityStatus; 
		
		switch (result.status) { // according to DIMACS solver requirements specification
		 	case 10: satisfiabilityStatus = "SATISFIABLE"; break; 
		 	case 20: satisfiabilityStatus = "UNSATISFIABLE"; break;
		 	default: satisfiabilityStatus = "UNKOWN"; break; 
		}
	
		char[] logEntry = problem ~ " , " ~ Integer.toString(cnt) ~ " , " ~ satisfiabilityStatus ~ " , " ~ Float.toString(cpu_time) ~ "\n";
		dst.append(logEntry); 
		
		return true; 
	        
	} catch(ProcessException e) {
    	Stdout.formatln("Problem when executing process: {}\n\n{}\n", startUpSolverCmd, e);
    	return false;  
	}
	
}

public int main(char[][] args)
{       
		if (args.length != 5) {
			printUsage(args); 
			return 1; 
		}
		
		char[] cmd = args[1]; 
		char[] cnt = args[2];
		char[] benchmarkDirectory = args[3]; 
		char[] outputFile = args[4];
		
		uint nofRepeats = 0; 
		
		try { 
			nofRepeats = Integer.toInt!(char)(cnt);
			if (nofRepeats < 0 ){
				Stdout.formatln("ERROR! illegal number of repeats specified: '{}'" , cnt);
				printUsage(args);
				return 1; 
			}

		} catch (IllegalArgumentException e){
			Stdout.formatln("ERROR! illegal number of repeats specified: '{}'" , cnt);
			printUsage(args);
			return 1;  
		}
		
		
		// Retrieve files from benchmark directory
		
		auto scan = (new FileScan)(benchmarkDirectory, ".cnf");
		
        Stdout.formatln("\nBenchmark directory contains {} problem files in DIMACS CNF format", scan.files.length).newline;
        
        
		// open the file for writing and write header
    	auto dst = new File(outputFile);
    	auto logEntry = "PROBLEM_NAME ,  #TRY , SAT_STATUS , CPU_TIME [sec]\n";
		dst.write(logEntry);
    	
    	
        foreach (file; scan.files){
                 Stdout.format("Running solver #{} times on problem {} : ", nofRepeats, file).flush();
                 solveProblem(file, nofRepeats, cmd, dst);
                 Stdout.formatln("  done.", file);
        }

        Stdout.formatln("\nFinished benchmarking.");
        Stdout.formatln("Results have been logged in file '{}'.", outputFile);
        
		return 0;
}