# News #

We just released version 0.1.1 of the SUDOKU solver. The changes are relatively minor but some useful functionality has been added:
  * DeescoverSUDOKU v0.1.1 now is based on the newest release of the TANGO runtime library v0.99.9
  * Code has been restructured slightly and interfaces have been simplified
  * We added support to enumerate different solutions of a given puzzle; this required a change in clients interface and therefore will break clients of version v0.1
  * The command line interface has been extended to check for solvalble problems also if they are uniquely solvable, i.e. if they have exactly one solution

# Introduction #

[SUDOKU](http://en.wikipedia.org/wiki/Sudoku) is a very popular number-placement puzzle. The game became famous in the western world a few years ago. Millions of people play SUDOKU on a regular basis and a wide range of sources for SUDOKU puzzles are available  online (e.g. [sudoku.com](http://www.sudoku.com/)) or in printed form.

Solving general SUDOKU problems (i.e. using n x m regions with n,m > 1) is known to be a hard computational problem:
Takayuki Yato showed in 2003 in (1) that it is an [NP-complete problem](http://en.wikipedia.org/wiki/NP-complete).

The NP-completeness of the game suggests an immediate solution approach based on SAT solvers. Solving SUDOKU is a combinatorial search problem that is as hard as solving the SAT problem for propositional logic. Hence, to solve SUDOKU puzzles we can use an efficient translation to propositional logic and subsequently use a SAT solver to do the hard work. This approach has been successfully investigated by various people, e.g in (2) by I. Lynce and J. Ouaknine.


# Using the solver #
You can find the executables for WINDOWS and LINUX operation systems in the 'bin" directory.

To call test solver on a SUDOKU problem using the command-line interface, the
problem must be represented as a plain ASCII file following the SUDOKU problem file
specification below.

Simply use the following command to invoke the solver:

```
	deescover-sudoku <sudoku-puzzle-file> 
```

where the problem file must be a plain SUDOKU problem file.

A few examples for testing the solver are included in the 'examples' directory.

## Usage: SUDOKU puzzle file specification ##

Puzzles are represented as plain ASCII files. Problem files
consist of 4 different types of lines:

  1. Lines starting with "c" are comments and ignored by the parser
  1. Lines starting with "p" are problem description lines and specify the dimensions (i.e. the layout) of the puzzle: two positive integers following the width and the height of the regions of the puzzle. The standard SUDOKU puzzles for instance use regions with width and height equal to 3.
  1. Empty lines are ignored and can be used to improve readabilty of the file in editors
  1. All other lines are considered as problem content lines, i.e. to specifiy the content of the SUDOKU puzzle (the given hints). The lines are read from top to bottom. Entries in the puzzle (hints) are separated by spaces. The problem entries are filled in row-wise from left to right. Fields that shall be left blank (free cells) are marked with non-positive integers (e.g. 0, -1) or 'X','x', or '-'. Line break can be used at any point to improve readability of the problem content description.

> The problem description line must occur exactly once and before any
> line specifying the content of the puzzle. Comments and empty lines
> can be used everywhere in the file. The problem content can be specified
> in an arbitrary number of lines. The

Here is an example of a valid SUDOKU problem description following the
required format:

```
c ---------------------------------------------
c -- A simple SUDOKU instance
c -- The problem is not in the common 3x3 format
c -- but instead uses regions of width 3 and 
c -- height 2
c ---------------------------------------------

c -- Define the problem to contain cell with width 3 and height 2 
p 3 2

c -- Now we can define the actual content of the puzzle

X X X   2 X 5
X X 6   X X X

1 4 X   X 2 6
X 5 X   X 3 X

X 3 X   X 1 X
X X X   3 X 4

c -- we could also use the following line to describe the same content
c -- X X X 2 X 5 X X 6 X X X 1 4 X X 2 6 X 5 X X 3 X X 3 X X 1 X X X X 3 X 4

c -- ... or these ones
c -- X X X 2 X 5 X X 6 X X X 1 4 X X 2 6 
c -- X 5 X X 3 X X 3 X X 1 X 
c -- X X X 3 X 4
```

# Try out this puzzle! #
The following SUDOKU puzzle, called "AI Escargot" , has been the hardest known
3x3 SUDOKU puzzle in 2006 (see for instance the following short [press announcement](http://www.news24.com/News24/Entertainment/Abroad/0,,2-1225-1243_2026307,00.html) or the book
http://www.amazon.com/AI-Escargot-Difficult-Sudoku-Puzzle/dp/1847534511 about this specific puzzle):

```
c ----------------------------------------
c -- The (infamous) AI-Escargot puzzle
c ----------------------------------------
c -- This SUDOKU puzzle is 
c -- considered as one of the
c -- hardest known SUDOKU problems
c -- for humans solving SUDOKU puzzles
c ----------------------------------------

p 3 3

1 x x   x x 7   x 9 x
x 3 x   x 2 x   x x 8
x x 9   6 x x   5 x x

x x 5   3 x x   9 x x
x 1 x   x 8 x   x x 2
6 x x   x x 4   x x x

3 x x   x x x   x 1 x 
x 4 x   x x x   x x 7
x x 7   x x x   3 x x
```


Some people take weeks to solve it whereas experienced SUDOKU experts might be able to solve it within 20min. Try DeescoverSUDOKU to solve the problem.
On my machine, it takes DeescoverSUDOKU less than 10ms to find the solution to the puzzle.

The amazing thing about the solver is that
  * it was very easy to implement, since only a straightforward transformation of SUDOKU puzzles into SAT problems is needed
  * the solver applies absolutely no domain-specific knowledge to construct the solution (besides the SUDOKU rules themselves). No SUDOKU specific heuristics or techniques are used within the solver implementation.
  * the solver is **very fast** and should usually outperform most (if not all) handcrafted solver for the SUDOKU puzzle.


In fact, today there are quite a number of 3x3 puzzles published on the Web that seem more demanding than the one above; see for instance:
http://www.sudoku.com/boards/viewtopic.php?t=4212


The following one is the top-rated one from the list at the website above and the hardest puzzle for our solver that we found so far:

```
  c ----------------------------------------
  c -- An even harder puzzle than 
  c -- the (infamous) AI-Escargot puzzle
  c ----------------------------------------
  p 3 3

  x x x  x x 1  x 2 x 
  3 x x  x 4 x  5 x x 
  x x x  6 x x  x x 7 

  x x 2  x x x  x x 6 
  x 5 x  x 3 x  x 8 x 
  4 x x  x x x  9 x x 

  9 x x  x x 2  x x x 
  x 8 x  x 5 x  4 x x 
  x x 1  7 x x  x x x 

```


# References #

  1. **Takayuki Yato:** _Complexity and completeness of finding another solution and its application to puzzles_, [Master's thesis](http://www-imai.is.s.u-tokyo.ac.jp/~yato/data2/MasterThesis.pdf), Graduate School of Science, Tokyo University, Japan, January 2003.
  1. **I. Lynce and J. Ouaknine:** _SUDOKU as a SAT Problem_, 9th International Symposium on Artificial Intelligence and Mathematics, [available online](http://anytime.cs.umass.edu/aimath06/proceedings/P34.pdf), January 2006