# Release Description #

Release v0.1 of Deescover represents a port of the [MiniSAT-2 solver](http://minisat.se/downloads/minisat2-070721.zip) (_version 070721_) to the **D programming language**.
The solver provides the same features as the above version of MiniSAT and applies the same default parameter settings.

Deescover v0.1 serves as a **baseline implementation** to compare with future variants and improvements of the solver.


# Requirements for Building the Software yourself #

In order to compile the source code yourself, you need to following software installed
on your computer:
  * [Digital Mars D Compiler](http://www.digitalmars.com/d/download.html) v1.035 (or later)
  * [TANGO D Runtime v0.99.7](http://www.dsource.org/projects/tango/wiki/PreviousReleases)
  * **WINDOWS only**: the **jake** build tool (included in the Windows distribution of TANGO above)
  * **LINUX only**: the **rebuild** build tool which is part of the [D Shared Software System](http://www.dsource.org/projects/dsss/) (DSSS).

The project contains a shell script 'make-release' that you can use to compile the project and build the command line version of the solver. You need to update the pathes in the script according to the installtion of the above mentioned software on your computer.