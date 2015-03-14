# Deescover Version 0.1 #
We evaluated the performance of the current release of Deescover (Version 0.1) on a well-known [benchmark suite](http://www.aloul.net/benchmarks.html) with hard industrial and handcrafted SAT problems.

The details for the experiment can be found [here](http://evanescent.googlecode.com/files/results-DAC2002-deescover-v0_1.html).

# Summary #
We can observe that Deescover v0.1 is consistently slower than Minisat 2 (around 1.18 - 4.8 times), but often faster than Picosat and RSat.

The slow-down of in comparison to Minisat 2 should be mainly caused by compiler technology: Deescover version 0.1 (written in D, compiled with the DMD D compiler) is a port of Minisat 2 that tries to reconstruct all low-level details of the solver we compared to in the experiment. Minisat 2 is written in C++ and compiled using the GNU c++ compiler. The observed slow-down in our experiment is consistent with the observations from the [Computer Language Benchmark Game](http://shootout.alioth.debian.org/gp4/benchmark.php?test=all&lang=dlang&lang2=gpp&box=1) comparing D and C++ for a range of rather simple programs with different characteristics.

Since all of the systems we compare our implementation to, are in fact leading state-of-the-art systems, we can conclude that Deescover is a very competitive implementation of a state-of-the-art SAT solver.