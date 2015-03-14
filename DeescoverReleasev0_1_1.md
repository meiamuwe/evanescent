## Release Description ##
Release v0.1.1 of Deescover is a modification of v0.1 to run with the newest version of the TANGO D runtime v0.99.9 released earlier this year. It also includes a minor bugfix but does neither restructure the code nor add additional functionality or optimizations in comparison to v0.1. The upcoming versions of deescover will do both.

## Requirements for Building the Software yourself ##
In order to compile the source code yourself, you need to following software installed on your computer:
  * [Digital Mars D Compiler](http://www.digitalmars.com/d/download.html) v1.041 (or later)
  * [TANGO D Runtime](http://www.dsource.org/projects/tango/) v0.99.9
  * WINDOWS only: the jake build tool (included in the Windows distribution of TANGO above)
  * LINUX only: the rebuild build tool which is part of the D Shared Software System (DSSS).

The project contains a shell script 'make-release' that you can use to compile the project and build the command line version of the solver. You need to update the pathes in the script according to the installtion of the above mentioned software on your computer.