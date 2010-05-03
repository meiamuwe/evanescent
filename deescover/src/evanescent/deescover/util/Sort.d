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
 * A module that provides some efficient implementations
 * of sorting algorithms on arrays
 * 
 * Authors: Uwe Keller
 * License: MIT
 * 
 * Version: 0.1 - April 2009, initial release         
 *
 */
module evanescent.deescover.util.Sort;

debug {
	import tango.io.Stdout;
}


template Sort (T) {

	alias bool function(T,T) Order;

	// A default order predicate on T
	public final bool defaultLessThan(T x,T y){
		return x <= y;
	}

	
	/**
	 * Checks if a list of data elements (represented as an array)
	 * are ordered ascending wrt the order lt
	 * 
	 */
	public final bool isSorted(T* array, int size, Order lt ){
		if (size > 1){
			T e1,e2;
			for (int i=0, j=1; j < size; i++, j++){
				e1 = array[i]; 
				e2 = array[j];
				if ( !( lt(e1,e2) || e1 == e2)  ){
					debug {
						Stdout.formatln("ERROR: found elements in wrong order: x = {}\ny = {}\n x < y = {}" , e1, e2, lt(e1,e2));
					}
					return false;
				}
			}
		}
		return true;
	}


	/**
	 * An implementation of Selection-Sort.
	 * 
	 * Sorting happens in-place (with constant additional memory)
	 * 
	 * Runs in O(size^2) time in the worst case, but is faster than
	 * Quicksort or Mergesort on small arrays.  
	 * 
	 * Params:
	 *     array = pointer to the first element of the array
	 *     size = number of elements in the array
	 *     lt = (optional) an order predicate on type T. If skipped
	 *     the default order < as defined by the type T is used. 
	 */
	public final void selectionSort(T* array, int size, Order lt = &defaultLessThan) 
	out { 
		debug{
			if (!isSorted(array, size, lt)){
				Stdout.formatln("ERROR: SelectionSort did not produce a sorted array: {}" , array[0..size]);
			}
		}
		assert( isSorted(array, size, lt) ); 
	}
	body {
		int     i, j, best_i;
		T       tmp;

		for (i = 0; i < size-1; i++){
			best_i = i;
			for (j = i+1; j < size; j++){
				if (lt(array[j], array[best_i])){
					best_i = j;
				}
			}
			// Swap elements at i and best_i
			tmp = array[i]; 
			array[i] = array[best_i], array[best_i] = tmp;
		}
	}


	
	/**
	 * An optimized implementation of Quicksort that
	 * uses Selection-Sort on small paritions instead of
	 * recursion further.
	 * 
	 * Runs in O ( size * log(size) ) time 'usually', worst-case
	 * running time is O (size^2). Pivot element is chosen
	 * as the middle element in a partition (i.e. this
	 * is no randomized version of quicksort).  
	 * 
	 * Params:
	 *     array = pointer to the first element of the array
	 *     size = number of elements in the array
	 *     lt = (optional) an order predicate on type T. If skipped
	 *     the default order < as defined by the type T is used. 
	 */
	void sort(T* array, int size, Order lt = &defaultLessThan)
	out { 
		debug{
			if (!isSorted(array, size, lt)){
				Stdout.formatln("ERROR: sort() did not produce a sorted array: {}" , array[0..size]);
			}
		}
		assert( isSorted(array, size, lt) ); 
	}
	body {
		if (size <= 15){ // use selection sort for small arrays
			selectionSort(array, size, lt);
		} else {
			
			 auto 	pivot_index = size / 2; 
			 T   	pivot = array[pivot_index]; 
			
			
			T           tmp;
			int         i = -1;
			int         j = size;

			for(;;){
				do i++; while( lt(array[i], pivot) ); //TODO: take overlap (== partition) into account
				do j--; while( lt(pivot, array[j]) );

				if (i >= j) break;

				// Swap elements at position i and j to maintain the invariant 
				// of presorting
				tmp = array[i]; 
				array[i] = array[j], array[j] = tmp;
			}
			
			 sort(array    , i     , lt);
			 sort(cast(T*) (array + i), size-i, lt);
		}
	}

}

debug {

	import tango.io.Stdout;

	private bool greaterThan(int x, int y){ return x > y; }
	alias void function(int*, int, Sort!(int).Order) IntSortingFunction; 
	
	private void testSortingFunction(IntSortingFunction sort){
		int[] array;  
		int[] sortedArray; 

		array = [];
		sortedArray = array.dup.sort.reverse;
		sort(array.ptr, array.length, &greaterThan); // Note: postconditions check sortedness	
		assert(array == sortedArray);  // compare agains the D built in sort of arrays

		array = [-21]; 
		sortedArray = array.dup.sort.reverse;
		sort(array.ptr, array.length, &greaterThan); 
		assert(array == sortedArray);  

		array = [1, 3, 5, 4, 2, 0]; 
		sortedArray = array.dup.sort.reverse;
		sort(array.ptr, array.length, &greaterThan); 
		assert(array == sortedArray); 

		array = [1, 3, -5, 4, -2, 1, 0, 1, 3, -5, 0];  
		array ~= [11, 13, -15, 14, -12, 11, 10, 11, 13, -15, 10]; 
		sortedArray = array.dup.sort.reverse;
		sort(array.ptr, array.length, &greaterThan); 
		assert(array == sortedArray); 

		array = [1, 3, -5, 4, -2, 1, 0, 1, 3, -5, 0];  
		array ~= [11, 13, -15, 14, -12, 11, 10, 11, 13, -15, 10]; 
		array ~= [211, 213, -215, 214, -212, 211, 210, 211, 213, -215, 210];
		array ~= [-4211, -4213, 4215, -4214, 4212, -4211, -4210, -4211, -4213, 4215, -4210];
		array ~= [-77, -77, -77, -77, -77, -77, -77, -77, -77, -77, -77, -77];
		sortedArray = array.dup.sort.reverse;
		sort(array.ptr, array.length, &greaterThan); 
		assert(array == sortedArray); 


	}

unittest {

	Stdout("Unit Testing [datastructures.Sort] ... ").newline;

	Stdout(" - Testing Selection Sort Implememtation: ");
	testSortingFunction(&Sort!(int).selectionSort); 
	Stdout(" ok.").newline; 
	
	Stdout(" - Testing Optimized Sorting Implememtation: ");
	testSortingFunction(&Sort!(int).sort); 
	Stdout(" ok.").newline; 
	

	Stdout("done.").newline();
}

}