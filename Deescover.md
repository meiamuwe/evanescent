![http://evanescent.googlecode.com/files/discover-logo.png](http://evanescent.googlecode.com/files/discover-logo.png)

# What is  deescover ? #
deescover is an efficient implementation of a modern conflict-driven SAT solver based on state-of-the-art techniques (1,2) such as
  * conflict-driven search
  * intelligent backtracking
  * clause learning
  * conflict-clause minimization
  * restarts
  * 2-watched literal scheme.

It also provides support for **incremental SAT solving** which is an interesting, performance improving feature for applications that create series' of related SAT problems.

Deescover is based on [MiniSAT-2](http://minisat.se/) which has been the winner of the international competition [SAT-Race 2006](http://fmv.jku.at/sat-race-2006/) and most recently in [SAT-Race 2008](http://baldur.iti.uka.de/sat-race-2008/index.html).

## Status ##
  * [Deescover Version 0.1.1](DeescoverReleasev0_1_1.md) : Minor update, May 4 2010
  * [Deescover Version 0.1](DeescoverReleasev0_1.md) : Initial release, April 26, 2009

## Usage ##
The solver can be used via a command-line interface or as a library for D applications.
It can process large formulas in clause normal form.

For users that interact with the solver using the command-line interface, please use the standard text-based [DIMACS CNF](http://www.cs.ubc.ca/~hoos/SATLIB/Benchmarks/SAT/satformat.ps) format to describe input formulas.

The [input and output of the solver](http://www.satcompetition.org/2004/format-solvers2004.html) follow the specification of the SAT competition.

# Performance #

Our implementation is not a toy implementation. In fact, it is competitive with leading state-of-the-art systems such as [Minisat 2](http://minisat.se/), [Picosat](http://fmv.jku.at/picosat/), or [RSat](http://reasoning.cs.ucla.edu/rsat/). Further details for the currrent version can be found [here](DeescoverPerformance.md).


# Benchmark Problems #
Some benchmark problems in the DIMACS CNF format:
  * [SATLIB Benchmark problems](http://www.cs.ubc.ca/~hoos/SATLIB/benchm.html)
  * [Problems used for SAT-Race 2008](http://baldur.iti.uka.de/sat-race-2008/downloads.html)

# References #

  1. M. W. Moskewicz, C. F. Madigan, Y. Zhao, L. Zhang, and S. Malik, "Chaff: engineering an efficient sat solver", in DAC '01: Proceedings of the 38th conference on Design automation.    New York, NY, USA: ACM Press, 2001, pp. 530-535. [available online](http://dx.doi.org/10.1145/378239.379017)
  1. N. Eén and N. Sörensson, "An extensible SAT-Solver", 2004, pp. 502-518. [available online](http://www.springerlink.com/content/x9uavq4vpvqntt23)
  1. N. Eén and A. Biere, "Effective Preprocessing in SAT through Variable and Clause Elimination," 2005, pp. 61-75. [available online](http://dx.doi.org/10.1007/11499107_5)