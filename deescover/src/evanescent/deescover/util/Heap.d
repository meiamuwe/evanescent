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
 * Authors: Uwe Keller
 * License: MIT
 * 
 * Version: 0.1 - April 2009, initial release
 */
module evanescent.deescover.util.Heap;

import evanescent.deescover.util.Vec;

debug{
	import tango.io.Stdout;
}

alias bool delegate (int, int) Comp;

/**
 * Implementation of a binary heap data structure for propositional variables
 * with support for decrease/increase key.
 * 
 * The heap is represented as a dynamic array. 
 * 
 * Authors: Uwe Keller
 */
public class Heap {
    Comp     lt;
    Vec!(int) heap;     // heap of ints
    Vec!(int) indices;  // int -> index in heap //TODO: make this a generic type (on something that is indexable) 

    // --------------------------------------------------------
	// - Index "traversal" functions
	// --------------------------------------------------------

    /** Compute the index of the left child of element at index i  */
    private final int left  (int i)
    in {
    	assert( 0 <= i && i < this.heap.size());
    }
    body {
    	return i*2+1; 
    }
    
    /** Compute the index of the left child of element at index i  */
    private  final int right (int i)
    in {
    	assert( 0 <= i && i < this.heap.size());
    }
    body {
    	return (i+1)*2; 
    } 

    /** Compute the index of the parent of the element at index i  */
    private  final int parent(int i)
    in {
    	assert( i > 0 );
    }
    body { 
    	return (i-1) >> 1; 
    }


    final void percolateUp(int i){
    	int x = heap[i];

    	while (i != 0 && lt(x, heap[parent(i)])){
    		heap[i]          = heap[parent(i)];
    		indices[heap[i]] = i;
    		i                = parent(i);
    	}

    	heap   [i] = x;
    	indices[x] = i;
    }
    
   


    final void percolateDown(int i){
        int x = heap[i];
        while (left(i) < heap.size()){
            int child = (right(i) < heap.size() && 
            	lt(heap[right(i)], heap[left(i)]) ? right(i) : left(i));
            
            if (!lt(heap[child], x)) {
            	break;
            }
            heap[i]          = heap[child];
            indices[heap[i]] = i;
            i                = child;
        }
        heap   [i] = x;
        indices[x] = i;
    }


    protected final bool heapProperty (int i) {
        return i >= heap.size()
            || ((i == 0 || !lt(heap[i], heap[parent(i)])) && 
            		heapProperty(left(i)) && heapProperty(right(i))); 
    }

    // --------------------------------------------------------
	// - Constructor
	// --------------------------------------------------------
    
    public this(Comp c){
    	this.lt = c;	
    	heap = new Vec!(int)();
    	indices = new Vec!(int)();
    }
    
    public final int size(){
    	return heap.size();
    }
    
    public final bool empty(){
    	return heap.size() == 0; 
    }
    public final bool inHeap(int n) { 
    	return (n < indices.size() && indices[n] >= 0); 
    }
    
    public final void decrease(int n)
    in { assert(inHeap(n)); }
    body {
    	percolateUp(indices[n]); 
    }

    public final void increase_ (int n) 
    in {  assert(inHeap(n)); }
    body { 
    	percolateDown(indices[n]); 
    }

    
    public final void insert(int n)
    in {
    	 assert( n >= 0 , "This implementation of heap can only deal with non-negative integers" );
    	 assert( inHeap(n) == false );
    }
    body {
    	
        indices.growTo( n + 1, -1);
        indices[n] = heap.size();
        heap.push(n);
        percolateUp(indices[n]); 
    
    }
    
    public public int  removeMin()
    in {
    	assert( this.size() > 0 );
    }
    body {
    	
    	int x            = heap[0];
    	heap[0]          = heap.last();
    	indices[heap[0]] = 0;
    	indices[x]       = -1;
    	heap.pop();
    	if (heap.size() > 1) {
    		percolateDown(0);
    	}
    	return x; 
    }

    public void clear(bool dealloc = false) { 
    	for (int i = 0; i < heap.size(); i++){
    		indices[heap[i]] = -1;
    	}

    	for (int i = 0; i < indices.size(); i++){
    		assert(indices[i] == -1);
    	}
    	
    	heap.clear(dealloc); 
    }

    // Fool proof variant of insert/decrease/increase
    public final void update(int n)
    {
        if (!inHeap(n)){
            insert(n);
        } else {
            percolateUp(indices[n]);
            percolateDown(indices[n]);
        }
    }


    public void filter(bool delegate(int) filt) 
    out {
    	for (int i = 0; i < heap.size(); i++){
    		assert(  heapProperty(heap[i]) );
    	}
    }
    body {                                                         
    	int i,j;
    	for (i = j = 0; i < heap.size(); i++){
    		if (filt(heap[i])){
    			heap[j]          = heap[i];
    			indices[heap[i]] = j++;
    		} else {
    			indices[heap[i]] = -1;
    		}
    	}

    	heap.shrink(i - j);
    	for (int k = heap.size() / 2 - 1; k >= 0; k--){
    		percolateDown(k);
    	}
    }
  
    public final int opIndex(uint i){
   	 return heap[i]; 
	}
        
}


unittest {
	Stdout("Unit Testing [datastructures.Heap] ... ");
	
	Heap h = new Heap( (int x, int y){ return x > y; } );
	
	h.insert(20);
	
	// Stdout.format("\n test 1");
	assert( h.inHeap(20) );
		
	// Stdout.format("\n test 2");
	assert( h.removeMin() == 20 );
	
	// Stdout.format("\n test 3");
	
	h = new Heap( (int x, int y){ return x > y; } );
	
	h.insert(10);
	h.insert(30);
	h.insert(120);
	h.insert(81);
	h.insert(80);
	h.insert(90);
	h.insert(0);
	
	assert( h.removeMin() == 120 );
	assert( h.removeMin() == 90 );
	assert( h.removeMin() == 81 );
	
	Stdout(" done.").newline();
	

}