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
module evanescent.deescover.util.Vec;

private import evanescent.deescover.util.Sort; 

private import tango.stdc.stdlib;
private import tango.core.Exception;
private import tango.core.Memory;

debug{
	private import tango.io.Stdout;
}

/**
 * Automatically resizable arrays / vectors. 
 * 
 * Authors: Uwe Keller,
 *          Niklas Een,
 *          Niklas Sorensson
 */
public class Vec(T) {
	/*
	 * A point to an array that stores the actual data
	 * The length of the array represents the current
	 * capacity and might exceed the number of stored
	 * data elements 
	 */
	private T* data_;
	/*
	 * Number of elements currently in the datastructure
	 */
	private int size_;
	
	
	private int cap_;
	
	invariant {
		assert (size_ <= cap_) ;
	}
	
	// --------------------------------------------------------
	// - Auxilliary comparisons
	// --------------------------------------------------------

	static final int imin(int x, int y) {
		int mask = (x-y) >> (int.sizeof*8-1);
		return (x&mask) + (y&(~mask)); 
	}

	static final int imax(int x, int y) {
		int mask = (y-x) >> (int.sizeof*8-1);
		return (x&mask) + (y&(~mask)); 
	}

	// --------------------------------------------------------
	// - Constructors and Destructors
	// --------------------------------------------------------
	
	public this(){
		data_ = null;
		size_ = 0;	
		cap_ = 0;
	}
	
	public this(int cap){
		data_ = null;
		size_ = 0;	
		cap_ = 0;
		growTo(cap);
	}
	
	public this(T[] array){	
		data_ = null;
		size_ = 0;
		grow(array.length);
		size_ = array.length;
    	for (int i = 0; i < size_; i++) {
    		data_[i] = array[i];
    	}
	}
	
	public ~this(){ 
		clear(true); 
	}

	// --------------------------------------------------------
	// -  Ownership of underlying array
	// --------------------------------------------------------
	
    public final T* release(){ 
    	T* ret = data_; 
    	data_ = null; 
    	size_ = 0; 
    	cap_ = 0; 
    	return ret;
    }
    
    // --------------------------------------------------------
	// -  Size operations
	// --------------------------------------------------------
	
    
    public final int size(){
    	return size_;
    } 
    
    public final int internalCapacity(){
    	return cap_;
    } 
    
    /**
     * Shrinks vector by the given number of elements
     * More specifically, the last nElems will be deleted
     * and the underlying container size will be resized
     * 
     * Params:
     *     nElems = number of elements (from the end of the
     *     vector) to be removed
     */
    public final void shrink(int nElems) 
    in {
    	assert(0 <= nElems && nElems <= size_);
    }
    body {
    	for (int i = 0; i < nElems; i++) {
    		size_--; 
    		static if ( is(T : Object) ) {
    			data_[size_] = null; // delete reference to facilitate GC
        	}
    	}
    }
    /**
     * Shrinks vector by the given number of elements
     * More specifically, the last nElems will not be deleted
     * but the underlying container size will be resized
     * such that these elements are no longer accessible
     * 
     * Params:
     *     nElems = number of elements (from the end of the
     *     vector) to be removed
     */
    public final void shrink_(int nElems) 
    in {
    	assert(0 <= nElems );
    	assert(nElems <= size_);
    }
    body {
    	size_ -= nElems;
    }
  
    // --------------------------------------------------------
	// -  Stack operations
	// --------------------------------------------------------
	
    /**
     * Removes the last element of the vector 
     * but not the memory
     *
     */
    public final void pop(){
    	size_--; 
    	static if ( is(T : Object) ) {
    		data_[size_] = null;
		}
    	
    }
    
    public final void capacity (int size) { 
    	grow(size); 
    }

    public final void push(){ 
    	if (size_ == cap_) { 
    		cap_ = imax(2, (cap_*3+1)>>1); 
    		data_=  cast(T*) tango.stdc.stdlib.realloc(data_, cap_ * T.sizeof);
    	} 
    	data_[size_] = T.init; 
    	size_++; 
    }
    
    public final void push (T elem){
    	if (size_ == cap_) { 
    		cap_ = imax(2, (cap_*3+1)>>1); 
    		data_=  cast(T*) tango.stdc.stdlib.realloc(data_, cap_ * T.sizeof);
    	} 
    	data_[size_] = elem; 
    	size_++; 
    }
    
    public final T last(){ 
    	return data_[size_ - 1]; 
    }
    
    public final T opIndex(uint i){
    	 return data_[i]; 
	}
    
    public final T opIndexAssign(T value, int i){
   	 	data_[i] = value;
   	 	return value;
	}
    
   
    public final void copyTo(Vec!(T) copy) { 
    	copy.clear(); 
    	copy.growTo(size_); 
    	for (int i = 0; i < size_; i++) {
    		copy[i] = data_[i];
    	}
    }
    
    public final void moveTo(Vec!(T) dest) { 
    	dest.clear(true); 
    	dest.data_ = this.data_; 
    	dest.size_ = this.size_; 
    	dest.cap_ = this.cap_; 
    	this.data_ = null; 
    	this.size_ = 0; 
    	this.cap_ = 0;
    }

    // --------------------------------------------------------
	// -  Growing and clearing the underlying container
	// --------------------------------------------------------
	
    /**
     * Ensures that the underlying container holding the elements
     * of the dynamic array is big enough to hold at least min_cap
     * elements. The container capacity might be bigger than the
     * given value afterwards. 
     * The size() of the dynamic array is $(B not changed) by this operation.
     */
    void grow(int min_cap) {
    	if (min_cap <= cap_) return;
        if (cap_ == 0) {
        	cap_ = (min_cap >= 2) ? min_cap : 2;
        } else {
        	do {
        		cap_ = (cap_*3+1) >> 1; 
         	} while (cap_ < min_cap);
        }
        data_=  cast(T*) tango.stdc.stdlib.realloc(data_, cap_ * T.sizeof);
    }
    
    void growTo(int size, T pad = T.init ) {
    	if (size_ >= size) return;
    	grow(size);
    	for (int i = size_; i < size; i++){
    		data_[i] = pad; // fill up new entries with given pad
    	}
    	size_ = size; 
    }

  
    public void clear(bool performDeAllocation = false) {
    	if (data_ !is null){
    		static if ( is(T : Object) ) {
    			for (int i = 0; i < size_; i++) {
    				data_[i] = null;
    			}
    		}
    		size_ = 0;
    		if (performDeAllocation) {
    			if (data_) {
    				tango.stdc.stdlib.free(data_);
    			}
    			data_ = null; 
    			cap_ = 0; 
    		}
    	}
    }
    
   public T[] elements(){
	   return data_[0..size_];
   }

    
   public void sort(Sort!(T).Order lt = &(Sort!(T).defaultLessThan) ){
	   Sort!(T).sort(data_, this.size_, lt);
   }
 
   final bool find(T t) { 
       int j = 0; 
       for (; j < this.size() && data_[j] != t; j++){}
       return (j < this.size());
   }
   
   final void remove(T t){
	   int j = 0;
	   for (; j < this.size() && data_[j] != t; j++){}
	   assert(j < this.size());
	   for (; j < this.size()-1; j++) { 
		   data_[j] = data_[j+1]; 
	   }
       this.pop();
   }

}


unittest {
	
	Stdout("Unit Testing [datastructures.Vec] ... ");

	Vec!(int) v = new Vec!(int)();
	
	v.push(3);
	v.push(2);
	v.push(-1);
	v.push(3);
	v.push(5);
	
	v.sort();
	
	v.pop();
	
	assert( v.size() == 4 );
	
	assert( v[0] == -1 ); 
	assert( v[1] == 2 ); 
	assert( v[2] == 3 ); 
	assert( v[3] == 3 ); 
	
	v.growTo(20, -3);
	
	assert( v.size() == 20 );
	for (int i = 4; i < 20; i++){
		assert( v[i] == -3);
	}
	
	v.shrink(5);
	
	assert( v.size() == 15 );
	
	assert( v[0] == -1 ); 
	assert( v[1] == 2 ); 
	assert( v[2] == 3 ); 
	assert( v[3] == 3 ); 
	for (int i = 4; i < 15; i++){
		assert( v[i] == -3);
	}
	
	v.growTo(18, 7);
	
	assert( v.size() == 18 );
	for (int i = 4; i < 15; i++){
		assert( v[i] == -3);
	}
	for (int i = 15; i < 18; i++){
		assert( v[i] == 7);
	}
	
	v.remove(3);
	assert(v.size() == 17);
	assert(v.find(3));
	
	v.remove(3);
	assert(v.size() == 16);
	assert(v.find(3) == false);
	
	
	Stdout(" done.").newline();
	
	
}