![http://evanescent.googlecode.com/files/evanescent-logo.png](http://evanescent.googlecode.com/files/evanescent-logo.png)

# Overview #
evanescent is a collection of tools for **reasoning in propositional logic** and provides implementations of inference engines in the [D programming language](http://www.digitalmars.com/d/).

The project is meant to be

  * a useful library for reasoning with propositional logic supporting various computational problems (e.g. SAT) and various algorithms for these problems.
  * a collection of efficient implementations based on state-of-the-art techniques
  * a platform for experiments with novel algorithms and implementation techniques
  * a stress test for the D programming language that allows to evaluate how suitable D is for developing high performance inference engines for hard computational problems


# Status #

For now the library focusses only on algorithms for the classical [propositional satisfiability problem](http://en.wikipedia.org/wiki/Boolean_satisfiability_problem) (SAT).

The library includes a state-of-the-art SAT solver [Deescover](https://github.com/meiamuwe/evanescent/blob/wiki/Deescover.md) written in D. At present, the deescover represents a port of the excellent [MiniSAT](http://minisat.se/) solver written in C++ by [Niklas Eén](http://een.se/niklas/) and [Niklas Sörensson](http://www.cs.chalmers.se/~nik/). deescover provides support for **incremental SAT solving**, i.e. solving series of similar SAT problems, as it is e.g. common for bounded-model checking and AI planning applications.


# Future Plans #

One line of work will be the improvement and optimization of the search-based SAT solver deescover. First steps in this direction are ongoing. This includes low-level datastructure and representational changes as well as work on the heuristic parts of the solver. For instance, we want to add a variant of deescover that implements _Decision-making with a Reference Point_ (DMRP) that has been introduced in 2008 by Goldberg.

We might further add **alternative algorithmic approaches** to solve the SAT problem: local-search based algorithms (e.g. WalkSAT , UnitWalk) and some suppport for [ordered binary decision diagrams](http://en.wikipedia.org/wiki/Binary_decision_diagram) (OBDDs) (perhaps simply an object-oriented wrapper to the CUDD library).

Another line of work will be on introducing algorithms that can work with **non-CNF based input**, but with general formulae in propositional logic. It is well-known that such solver can outperform CNF-based solvers in specific applications.  Concretely, we want to develop a DPLL-based Circuit-SAT solver.

Further, we aim at providing fast and memory-efficient algorithms to the **all-solutions SAT problem**, i.e. compute _all models_ of  given a propositional formula. Such algorithms are interesting for model checking applications or compilation of formulae to OBDDs for instance.

In the long run, we may also extend the library by **algorithms for non-standard inference tasks** which became interesting only recently and have applications in AI and Bioinformatics, e.g. weighted SAT-problems, pseudo-boolean constraints, model counting etc.

# Available Tools and Inference Engines #

The following inference engines and tools are part of the evanescent library:

  * [Deescover](../wiki/Deescover.md): a **search-based SAT-solver** in the style of [CHAFF](http://www.princeton.edu/~chaff/) and [MiniSAT](http://minisat.se/) with support for **incremental SAT solving**.

# Applications #

To demonstrate the use of the tools in the evanescent toolbox, we include the following applications

  * [DeescoverSUDOKU](../wiki/DeescoverSUDOKU.md): a fast solver for general SUDOKU puzzles based on the [Deescover](../wiki/Deescover.md) SAT solver.

# News #
  * **March 14, 2015**: 
    * Migrated codebase from Goole Code to GitHub
 
  * **May 3, 2010**:
    * Released the evanescent tool suite version 0.1.1
    * Released version 0.1.1 of the [Deescover](../wiki/Deescover.md) SAT solver.
    * Released [DeescoverSUDOKU](../wiki/DeescoverSUDOKU.md) version 0.1.1

  * **April 26, 2009**:
    * Released the evanescent tool suite version 0.1
    * Released version 0.1 of the [Deescover](../wiki/Deescover.md) SAT solver.
    * Released [DeescoverSUDOKU](../wiki/DeescoverSUDOKU.md) version 0.1

# Related Sites #
evanescent is also listed at the major forum for open-source projects in D, [DSource.org](http://www.dsource.org/projects/evanescent/).
