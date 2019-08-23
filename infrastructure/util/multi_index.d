module util.multi_index;

/**
 * TODO:
 *  random access index
 *   insertAfter ? insertBefore ?
 *  fix BitHackery
 *  make MutableView a per index thing?
 *  modify(r, mod, rollback)
 *  contain const/immutable value types
 *  other indices?
 *  dup
 *  make reserve perform reserve on all appropriate indices?
 *  ensure MultiIndexContainer is strongly exception safe.
 */

version = BucketHackery;

import std.array;
import std.range;
import std.exception: enforce;
import std.algorithm: find, swap, copy, fill, max, startsWith, moveAll;
import std.algorithm: move, sort, map;
import std.traits: isImplicitlyConvertible, isDynamicArray;
import util.replace: Replace;
import std.typetuple: TypeTuple, staticMap, NoDuplicates, staticIndexOf, allSatisfy;
import std.functional: unaryFun, binaryFun;
import std.string: format;
version(PtrHackery){
    import core.bitop: bt, bts, btr;
}

// stopgap allocator implementation
// drat: using GCAllocator is probably less efficient than arr.length = i
// cf GC.extend

struct GCAllocator{
    static T* allocate(T)(size_t i) {
        return (new T[](i)).ptr;
    }

    static void deallocate(T)(T* t) {
        // gc deallocates when it does. whee.
    }

}

import core.stdc.stdlib: malloc, free;
import core.stdc.string: memset;
import core.memory: GC;
import core.exception: OutOfMemoryError;

struct MallocAllocator{
    static T* allocate(T)(size_t i) {
        T* p = cast(T*) malloc(T.sizeof * i);
        memset(p, 0, T.sizeof * i);
        if(!p) throw new OutOfMemoryError();
        GC.addRange(cast(void*) p, T.sizeof * i);
        return p;
    }
    static void deallocate(T)(T* t) {
        GC.removeRange(cast(void*) t);
        free(t);
    }
}

import std.traits: isIterable, isNarrowString, ForeachType, Unqual;
// stolen from phobos and modified.
// when phobos gets real allocators, this hopefully will go away.
Unqual!(ForeachType!Range)[] allocatedArray(Allocator,Range)(Range r)
if (isIterable!Range && !isNarrowString!Range)
{
    alias Unqual!(ForeachType!Range) E;
    static if (hasLength!Range)
    {
        if(r.length == 0) return null;

        auto result = Allocator.allocate!E(r.length)[0 .. r.length];

        size_t i = 0;
        foreach (e; r)
        {
            // hacky
            static if (is(typeof(e.opAssign(e))))
            {
                // this should be in-place construction
                emplace!E(result.ptr + i, e);
            }
            else
            {
                result[i] = e;
            }
            i++;
        }
        return result;
    }
    else
    {
        auto result = Allocator.allocate!(Unqual!E)(1)[0 .. 1];
        size_t i = 0;
        foreach (e; r)
        {
            result[i] = e;
            i++;
            if(i == result.length) {
                auto nlen = result.length*2+1;
                auto nresult = Allocator.allocate!(Unqual!E)(nlen)[0 .. nlen];
                auto rest = moveAll(result, nresult);
                fill(rest, E.init);
                Allocator.deallocate(result.ptr);
                result = nresult;
            }
        }
        return result[0 .. i];
    }
}

template IsAllocator(T) {
    enum bool IsAllocator = is(typeof(T.allocate!int(1)) == int*) &&
        is(typeof(T.deallocate!int((int*).init)) == void);
}

/// A doubly linked list index.
template Sequenced() {
    // no memory allocations occur within this index.
    enum bool BenefitsFromSignals = false;
    // damn you, ddoc
    /// _
    template Inner(ThisContainer,ThisNode, Value, ValueView, size_t N, Allocator) {

/**
Defines the index' primary range, which embodies a
bidirectional range
*/
        struct SequencedRange(bool is_const) {
            static if(is_const) {
                alias const(ThisNode) Node;
                alias const(ThisContainer) Container;
            }else {
                alias ThisContainer Container;
                alias ThisNode Node;
            }
            Container c;
            Node* _front, _back;
            alias _front front_node;
            alias _back back_node;

            this(Container _c, Node* f, Node* b) {
                c = _c;
                _front = f;
                _back = b;
            }

            @property bool empty() {
                return
                    !(_front && _back &&
                    _front !is _back.index!N.next &&
                    _back !is _front.index!N.prev);
            }
            @property front(){
                return _front.value;
            }
            @property back(){
                return _back.value;
            }

            @property save(){ return this; }

            void popFront()
            in{
                assert(_front !is _front.index!N.next);
            }body{
                _front = _front.index!N.next;
            }

            void popBack(){
                _back = _back.index!N.prev;
            }
        }

        alias TypeTuple!(N,SequencedRange) IndexTuple;
        alias TypeTuple!(N) NodeTuple;

        // node implementation
        mixin template NodeMixin(size_t N){
            typeof(this)* next, prev;

            // inserts node between this and this.next
            // a,b = this, this.next; then
            // old: a <-> b, null <- node -> null
            // new: a <-> node <-> b
            void insertNext(typeof(this)* node) nothrow
                in{
                    assert(node !is null);
                    assert(node.index!N.prev is null,
                            format("node.prev = %x",node.index!N.prev));
                    assert(node.index!N.next is null,
                            format("node.next = %x",node.index!N.next));
                }body{
                    typeof(this)* n = next;
                    next = node;
                    node.index!N.prev = &this;
                    if(n !is null) n.index!N.prev = node;
                    node.index!N.next = n;
                }

            // a,b = this, this.prev; then
            // old: b <-> a, null <- node -> null
            // new: b <-> node <-> a
            void insertPrev(typeof(this)* node) nothrow
                in{
                    assert(node !is null);
                    assert(node.index!N.prev is null,
                            format("node.prev = %x",node.index!N.prev));
                    assert(node.index!N.next is null,
                            format("node.next = %x",node.index!N.next));
                }body{
                    typeof(this)* p = prev;
                    if(p !is null) p.index!N.next = node;
                    node.index!N.prev = p;
                    prev = node;
                    node.index!N.next = &this;
                }

            // a,b,c = this, this.next, this.next.next; then
            // old: a <-> b <-> c
            // new: a <-> c, null <- b -> null
            typeof(this)* removeNext() nothrow
                in{
                    assert(next);
                }body{
                    typeof(this)* n = next, nn = n.index!N.next;
                    next = nn;
                    if(nn) nn.index!N.prev = &this;
                    n.index!N.prev = n.index!N.next = null;
                    return n;
                }

            // a,b,c = this, this.prev, this.prev.prev; then
            // old: c <-> b <-> a
            // new: c <-> a, null <- b -> null
            typeof(this)* removePrev() nothrow
                in{
                    assert(prev);
                }body{
                    typeof(this)* p = prev, pp = p.index!N.prev;
                    prev = pp;
                    if(pp) pp.index!N.next = &this;
                    p.index!N.prev = p.index!N.next = null;
                    return p;
                }
        }

 /// Sequenced index implementation
 ///
 /// Requirements: the following symbols must be
 /// defined in the scope in which this index is mixed in:
 ///
 // dangit, ddoc, show my single starting underscore!
 /// ThisNode, Value, __InsertAllBut!N, __InsertAll,  __Replace,
 /// __RemoveAllBut!N, node_count
        mixin template IndexMixin(size_t N, alias Range_0){
            ThisNode* _front, _back;
            alias Range_0!false SeqRange;
            alias Range_0!true ConstSeqRange;

            template IsMyRange(T) {
                enum bool IsMyRange =
                    is(T == SeqRange) ||
                    is(T == ConstSeqRange);
            }

/**
Returns the number of elements in the container.

Complexity: $(BIGOH 1).
*/
            @property size_t length() const{
                return node_count;
            }

/**
Property returning $(D true) if and only if the container has no
elements.

Complexity: $(BIGOH 1)
*/
            @property bool empty() const{
                return node_count == 0;
            }

/**
Fetch a range that spans all the elements in the container.

Complexity: $(BIGOH 1)
*/
            SeqRange opSlice(){
                return SeqRange(this, _front, _back);
            }

            ConstSeqRange opSlice() const{
                return ConstSeqRange(this, _front, _back);
            }

/**
Complexity: $(BIGOH 1)
*/
            @property front() inout{
                return _front.value;
            }

/**
Complexity: $(BIGOH r(n)); $(BR) $(BIGOH 1) for this index
*/
            @property void front(Value value){
                _Replace(_front, value);
            }


            /**
             * Complexity: $(BIGOH 1)
             */
            @property back() inout{
                return _back.value;
            }

            /**
             * Complexity: $(BIGOH r(n))
             */
            @property void back(Value value) {
                _Replace(_back, value);
            }

            void _ClearIndex() {
                _front = _back = null;
            }

            void clear(){
                _Clear();
            }
/**
Moves moveme.front to the position before tohere.front and inc both ranges.
Probably not safe to use either range afterwards, but who knows.
Preconditions: moveme and tohere are both ranges of the same container.
Postconditions: moveme.front is incremented
Complexity: $(BIGOH 1)
*/
            void relocateFront(PosRange)(ref PosRange moveme, PosRange tohere)
            if(is(ElementType!PosRange == Position!(ThisNode)) ||
               is(PosRange == SeqRange))
            in{
                // rubbish, now we can't ensure two ranges are from same
                // index, container
                static if(is(PosRange == SeqRange)) {
                    // well, do it if you can
                    assert(moveme.c == tohere.c);
                    assert(moveme.front_node);
                    assert(tohere.front_node);
                }else {
                    assert(moveme.front.node);
                    assert(tohere.front.node);
                }
            }body{
                static if(is(PosRange == SeqRange)) {
                    ThisNode* m = moveme.front_node;
                    ThisNode* n = tohere.front_node;
                }else {
                    ThisNode* m = moveme.front.node;
                    ThisNode* n = tohere.front.node;
                }
                moveme.popFront();
                if (m is n) return; //??
                if (m is n.index!N.prev) return; //??
                _Remove(m);
                n.index!N.insertPrev(m);
                if(n is _front) _front = m;
            }
/**
Moves moveme.back to the position after tohere.back and dec both ranges.
Probably not safe to use either range afterwards, but who knows.
Preconditions: moveme and tohere are both ranges of the same container
Postconditions: moveme.back is decremented
Complexity: $(BIGOH 1)
*/
            void relocateBack(PosRange)(ref PosRange moveme, PosRange tohere)
            if(is(ElementType!PosRange == Position!(ThisNode)) ||
               is(PosRange == SeqRange))
            in{
                static if(is(PosRange == SeqRange)) {
                    assert(moveme.c == tohere.c);
                    assert(moveme.back_node);
                    assert(tohere.back_node);
                }else {
                    assert(moveme.back.node);
                    assert(tohere.back.node);
                }
            }body{
                static if(is(PosRange == SeqRange)) {
                    ThisNode* m = moveme.back_node;
                    ThisNode* n = tohere.back_node;
                }else{
                    ThisNode* m = moveme.back.node;
                    ThisNode* n = tohere.back.node;
                }
                moveme.popBack();
                if (m is n) return; //??
                if (m is n.index!N.next) return; //??
                _Remove(m);
                n.index!N.insertNext(m);
                if(n is _back) _back = m;
            }

            void modify(SomeRange, Modifier)(SomeRange r, Modifier mod)
            if(is(SomeRange == SeqRange) ||
               is(ElementType!SomeRange == Position!(ThisNode))) {
                while(!r.empty) {
                    static if(is(SomeRange == SeqRange)){
                        ThisNode* node = r.front_node;
                    }else{
                        ThisNode* node = r.front.node;
                    }
                    _Modify(node, mod);
                    r.popFront();
                }
            }

/**
Replaces r.front with value
Returns: whether replacement succeeded
Complexity: ??
*/
            bool replace(Position!ThisNode r, Value value)
            {
                return _Replace(r.node, value);
            }

            bool _insertFront(ThisNode* node) nothrow
                in{
                    assert(node !is null);
                    assert(node.index!N.prev is null);
                    assert(node.index!N.next is null);
                }body{
                    if(_front is null){
                        debug assert(_back is null);
                        _front = _back = node;
                    }else{
                        _front.index!N.insertPrev(node);
                        _front = node;
                    }

                    return true;
                }

            alias _insertBack _Insert;

            bool _insertBack(ThisNode* node) nothrow
                in{
                    debug assert (node !is null);
                }body{
                    if(_front is null){
                        debug assert(_back is null);
                        _front = _back = node;
                    }else{
                        _back.index!N.insertNext(node);
                        _back = node;
                    }

                    return true;
                }

/++
Inserts every element of stuff not rejected by another index into the front
of the index.
Returns:
The number of elements inserted.
Complexity: $(BIGOH n $(SUB stuff) * i(n)); $(BR) $(BIGOH n $(SUB stuff)) for
this index
+/
            size_t insertFront(SomeRange)(SomeRange stuff)
                if(isInputRange!SomeRange &&
                        isImplicitlyConvertible!(ElementType!SomeRange,
                            ValueView))
                {
                    import std.array: empty, front;
                    if(stuff.empty) return 0;
                    size_t count = 0;
                    ThisNode* prev;
                    while(count == 0 && !stuff.empty){
                        prev = _InsertAllBut!N(stuff.front);
                        if (!prev) continue;
                        _insertFront(prev);
                        stuff.popFront();
                        count++;
                    }
                    foreach(item; stuff){
                        ThisNode* node = _InsertAllBut!N(item);
                        if (!node) continue;
                        prev.index!N.insertNext(node);
                        prev = node;
                        count ++;
                    }
                    return count;
                }

/++
Inserts value into the front of the sequence, if no other index rejects value
Returns:
The number if elements inserted into the index.
Complexity: $(BIGOH i(n)); $(BR) $(BIGOH 1) for this index
+/
            size_t insertFront(SomeValue)(SomeValue value)
                if(isImplicitlyConvertible!(SomeValue, ValueView)){
                    ThisNode* node = _InsertAllBut!N(value);
                    if(!node) return 0;
                    _insertFront(node);
                    return 1;
                }

/++
Inserts every element of stuff not rejected by another index into the back
of the index.
Returns:
The number of elements inserted.
Complexity: $(BIGOH n $(SUB stuff) * i(n)); $(BR) $(BIGOH n $(SUB stuff)) for
this index
+/
            size_t insertBack (SomeRange)(SomeRange stuff)
                if(isInputRange!SomeRange &&
                        isImplicitlyConvertible!(ElementType!SomeRange, ValueView))
                {
                    size_t count = 0;

                    foreach(item; stuff){
                        count += insertBack(item);
                    }
                    return count;
                }

/++
Inserts value into the back of the sequence, if no other index rejects value
Returns:
The number if elements inserted into the index.
Complexity: $(BIGOH i(n)); $(BR) $(BIGOH 1) for this index
+/
            size_t insertBack(SomeValue)(SomeValue value)
                if(isImplicitlyConvertible!(SomeValue, ValueView)){
                    ThisNode* node = _InsertAllBut!N(value);
                    if (!node) return 0;
                    _insertBack(node);
                    return 1;
                }

/++
Forwards to insertBack
+/
            alias insertBack insert;

            // reckon we'll trust n is somewhere between _front and _back
            void _Remove(ThisNode* n){
                if(n is _front){
                    _removeFront();
                }else{
                    ThisNode* prev = n.index!N.prev;
                    prev.index!N.removeNext();
                    if(n is _back) _back = prev;
                }
            }

            ThisNode* _removeFront()
                in{
                    assert(_back !is null);
                    assert(_front !is null);
                }body{
                    ThisNode* n = _front;
                    if(_back == _front){
                        _back = _front = null;
                    }else{
                        _front = _front.index!N.next;
                        n.index!N.next = null;
                        _front.index!N.prev = null;
                    }
                    return n;
                }

/++
Removes the value at the front of the index from the container.
Precondition: $(D !empty)
Complexity: $(BIGOH d(n)); $(BIGOH 1) for this index
+/
            void removeFront(){
                _RemoveAll(_front);
            }

/++
Removes the value at the back of the index from the container.
Precondition: $(D !empty)
Complexity: $(BIGOH d(n)); $(BR) $(BIGOH 1) for this index
+/
            void removeBack(){
                _RemoveAll(_back);
            }
/++
Forwards to removeBack
+/
            alias removeBack removeAny;

/++
Removes the values of r from the container.
Preconditions: r came from this index
Complexity: $(BIGOH n $(SUB r) * d(n)), $(BR) $(BIGOH n $(SUB r)) for this index
+/
            SeqRange remove(R)(R r)
            if(is(R == SeqRange) ||
               is(ElementType!R == Position!ThisNode))
            {
                while(!r.empty){
                    static if(is(R == SeqRange)){
                        ThisNode* f = r.front_node;
                    }else{
                        ThisNode* f = r.front.node;
                        r.front.obliterated = true;
                    }
                    r.popFront();
                    _RemoveAll(f);
                }
                return SeqRange(this,null,null);
            }
              // in: old is from this index
              // out: old is disconnected from this index and replaced by newnode
              void _NodeReplace(ThisNode* old, ThisNode* newnode) {
                  ThisNode* next = old.index!N.next;
                  ThisNode* prev = old.index!N.prev;
                  newnode.index!N.next = next;
                  newnode.index!N.prev = prev;
                  if(next) {
                      next.index!N.prev = newnode;
                  }else {
                      assert(old is _back);
                      _back = newnode;
                  }
                  if(prev) {
                      prev.index!N.next = newnode;
                  }else{
                      assert(old is _front);
                      _front = newnode;
                  }

                  old.index!N.prev = null;
                  old.index!N.next = null;
              }


            void _Check(){
            }

            string toString0(){
                string r = "[";
                auto rng = opSlice();
                while(!rng.empty){
                    r ~= format("%s", rng.front);
                    rng.popFront();
                    r ~= rng.empty ? "]" : ", ";
                }
                return r;
            }

            private SeqRange fromNode(ThisNode* n){
                return SeqRange(this, n, this.index!N._back);
            }
        }

    }
}

/// A random access index.
template RandomAccess() {
    enum bool BenefitsFromSignals = false;
    /// _
    template Inner(ThisContainer,ThisNode, Value, ValueView, size_t N, Allocator) {
        alias TypeTuple!() NodeTuple;
        alias TypeTuple!(N,ThisContainer) IndexTuple;

        // node implementation
        mixin template NodeMixin(){
            size_t _index;
        }

        /// index implementation
        ///
        /// Requirements: the following symbols must be
        /// defined in the scope in which this index is mixed in:
        ///
        // dangit, ddoc, show my single starting underscore!
        /// ThisNode, Value, __InsertAllBut!N, __InsertAll,  __Replace,
        /// __RemoveAllBut!N, node_count
        mixin template IndexMixin(size_t N, ThisContainer){
            ThisNode*[] ra;

            /// Defines the index' primary range, which embodies a
            /// random access range
            struct RARangeT(bool is_const) {
                static if(is_const) {
                    alias const(ThisNode) Node;
                    alias const(ThisContainer) Container;
                }else {
                    alias ThisContainer Container;
                    alias ThisNode Node;
                }
                Container c;
                size_t s, e;

                this(Container _c, size_t _s, size_t _e) {
                    c = _c;
                    s = _s;
                    e = _e;
                }

                private @property Node* front_node(){
                    assert(s < e && e <= c.index!N.length);
                    return c.index!N.ra[s];
                }
                private @property Node* back_node() {
                    assert(s < e && e <= c.index!N.length);
                    return c.index!N.ra[e-1];
                }

                @property front(){
                    assert(s < e && e <= c.index!N.length);
                    return front_node.value;
                }

                void popFront(){ s++; }

                @property bool empty()const{ return s >= e; }
                @property size_t length()const { return s <= e ? e-s : 0; }

                @property back(){
                    return back_node.value;
                }

                void popBack(){ e--; }

                @property save(){ return this; }

                auto opIndex(size_t i){ return nth_node(i).value; }

                private auto nth_node(size_t i) { return c.index!N.ra[i]; }

                auto opSlice(size_t a, size_t b) {
                    assert(a <= b && b < length);
                    return RARangeT(c, s+a, s+b);
                }

                static if(!is_const) {
                    private @property front_node(ThisNode* n) {
                        assert(s < e && e <= c.index!N.length);
                        c.index!N.ra[s] = n;
                    }
                }
            }


            alias RARangeT!true ConstRARange;
            alias RARangeT!false RARange;

            /*
    static assert(is(typeof(
    {
        RARange r = void;       // can define a range object
        if (r.empty) {}   // can test for empty
        r.popFront();     // can invoke popFront()
        auto h = r.front; // can get the front of the range
    })));

            static assert(isInputRange!RARange);
            static assert(isForwardRange!RARange);
            static assert(isBidirectionalRange!RARange);
            static assert(isRandomAccessRange!RARange);
            */

            template IsMyRange(T) {
                enum bool IsMyRange =
                    is(T == RARange) ||
                    is(T == ConstRARange);
            }


/**
Fetch a range that spans all the elements in the container.

Complexity: $(BIGOH 1)
*/
            RARange opSlice (){
                return RARange(this, 0, node_count);
            }
            ConstRARange opSlice () const{
                return ConstRARange(this, 0, node_count);
            }

/**
Fetch a range that spans all the elements in the container from
index $(D a) (inclusive) to index $(D b) (exclusive).
Preconditions: a <= b && b <= length

Complexity: $(BIGOH 1)
*/
            RARange opSlice(size_t a, size_t b){
                enforce(a <= b && b <= length);
                return RARange(this, a, b);
            }
            ConstRARange opSlice(size_t a, size_t b) const{
                enforce(a <= b && b <= length);
                return ConstRARange(this, a, b);
            }

/**
Returns the number of elements in the container.

Complexity: $(BIGOH 1).
*/
            @property size_t length()const{
                return node_count;
            }

/**
Property returning $(D true) if and only if the container has no elements.

Complexity: $(BIGOH 1)
*/
            @property bool empty() const{
                return node_count == 0;
            }

/**
Returns the _capacity of the index, which is the length of the
underlying store
*/
            @property size_t capacity() const{
                return ra.length;
            }

/**
Ensures sufficient capacity to accommodate $(D count) elements.

Postcondition: $(D capacity >= count)

Complexity: $(BIGOH ??) if $(D e > capacity),
otherwise $(BIGOH 1).
*/
            void reserve(size_t count){
                if(ra.length < count){
                    auto newra = Allocator.allocate!(ThisNode*)(count)[0 .. count];
                    auto rest = moveAll(ra, newra);
                    fill(rest, null);
                    Allocator.deallocate(ra.ptr);
                    ra = newra;
                }
            }

/**
Complexity: $(BIGOH 1)
*/
            @property front() inout{
                return ra[0].value;
            }

/**
Complexity: $(BIGOH r(n)); $(BR) $(BIGOH 1) for this index
*/
            @property void front(ValueView value){
                _Replace(ra[0], cast(Value) value);
            }

/**
Complexity: $(BIGOH 1)
*/
            @property back() inout{
                return ra[node_count-1].value;
            }

/**
Complexity: $(BIGOH r(n)); $(BR) $(BIGOH 1) for this index
*/
            @property void back(ValueView value){
                _Replace(ra[node_count-1], cast(Value) value);
            }

            void _ClearIndex(){
                fill(ra, (ThisNode*).init);
            }

            /// _
            void clear(){
                _Clear();
            }

/**
Preconditions: i < length
Complexity: $(BIGOH 1)
*/
            auto opIndex(size_t i) inout{
                enforce(i < length);
                return ra[i].value;
            }
/**
Sets index i to value, unless another index refuses value
Preconditions: i < length
Returns: the resulting _value at index i
Complexity: $(BIGOH r(n)); $(BR) $(BIGOH 1) for this index
*/
            ValueView opIndexAssign(ValueView value, size_t i){
                enforce(i < length);
                _Replace(ra[i], cast(Value) value);
                return ra[i].value;
            }

/**
Swaps element at index $(D i) with element at index $(D j).
Preconditions: i < length && j < length
Complexity: $(BIGOH 1)
*/
            void swapAt( size_t i, size_t j){
                enforce(i < length && j < length);
                swap(ra[i], ra[j]);
                swap(ra[i].index!N._index, ra[j].index!N._index);
            }

/**
Removes the last element from this index.
Preconditions: !empty
Complexity: $(BIGOH d(n)); $(BR) $(BIGOH 1) for this index
*/
            void removeBack(){
                _RemoveAllBut!N(ra[node_count-1]);
                dealloc(ra[node_count]);
                ra[node_count] = null;
            }

            alias removeBack removeAny;

            void _Remove(ThisNode* n){
                size_t i = n.index!N._index;
                copy(ra[i+1 .. node_count], ra[i .. node_count-1]);
                foreach(k,r; ra[i .. node_count-1])
                    r.index!N._index = i+k;
                ra[node_count-1] = null;
                return;
            }

/**
inserts value in the back of this index.
Complexity: $(BIGOH i(n)), $(BR) amortized $(BIGOH 1) for this index
*/
            size_t insertBack(SomeValue)(SomeValue value)
            if(isImplicitlyConvertible!(SomeValue, ValueView))
            {
                ThisNode* n = _InsertAllBut!N(value);
                if (!n) return 0;
                node_count--;
                _Insert(n);
                node_count++;
                return 1;
            }

/**
inserts elements of r in the back of this index.
Complexity: $(BIGOH n $(SUB r) * i(n)), $(BR) amortized $(BIGOH n $(SUB r))
for this index
*/
            size_t insertBack(SomeRange)(SomeRange r)
            if(isImplicitlyConvertible!(ElementType!SomeRange, ValueView))
            {
                enum haslen = hasLength!SomeRange;

                static if(haslen){
                    if(capacity() < node_count + r.length){
                        reserve(node_count + r.length);
                    }
                }
                size_t count = 0;
                foreach(e; r){
                    count += insertBack(e);
                }
                return count;
            }

            void _Insert(ThisNode* node){
                if (node_count >= ra.length){
                    reserve(max(ra.length * 2 + 1, node_count+1));
                }
                ra[node_count] = node;
                ra[node_count].index!N._index = node_count;
            }

/**
inserts elements of r in the back of this index.
Complexity: $(BIGOH n $(SUB r) * i(n)), $(BR) amortized $(BIGOH n $(SUB r))
for this index
*/
            alias insertBack insert;

/**
Perform mod on r.front and performs any necessary fixups to container's
indices. If the result of mod violates any index' invariant, r.front is
removed from the container.
Preconditions: !r.empty, $(BR)
mod is a callable of the form void mod(ref Value)
Complexity: $(BIGOH m(n)), $(BR) $(BIGOH 1) for this index
*/

            void modify(SomeRange, Modifier)(SomeRange r, Modifier mod)
            if(is(SomeRange == RARange) ||
               is(ElementType!SomeRange == Position!(ThisNode))) {
                while(!r.empty) {
                    static if(is(SomeRange == RARange)){
                        ThisNode* node = r.front_node;
                    }else{
                        ThisNode* node = r.front.node;
                    }
                    _Modify(node, mod);
                    r.popFront();
                }
            }
/**
Replaces r.front with value
Returns: whether replacement succeeded
Complexity: ??
*/
            bool replace(Position!ThisNode r, ValueView value) {
                return _Replace(r.node, cast(Value) value);
            }

            static bool _RemovePred(Position!ThisNode a, Position!ThisNode b) {
                return a.node.index!N._index < b.node.index!N._index;
            }
            static size_t _RemoveUn(Position!ThisNode a) {
                return a.node.index!N._index;
            }
            static size_t _RemoveUn2(ThisNode* a) {
                return a.index!N._index;
            }
/**
removes elements of r from this container.
Complexity: $(BIGOH n $(SUB r) * d(n)), $(BR) $(BIGOH n)
for this index
*/
            RARange remove(Range)(Range r)
            if(is(Range == RARange) ||
               is(ElementType!Range == Position!ThisNode)) {
                static if(is(Range == RARange)) {
                    // definitely contiguous
                    size_t _length = node_count;
                    size_t s = r.front_node.index!N._index;
                    size_t e = r.back_node.index!N._index+1;
                    size_t newlen = _length - (e-s);
                    while(!r.empty){
                        ThisNode* node = r.front_node;
                        _RemoveAllBut!N(node);
                        dealloc(node);
                        r.popFront();
                    }
                    copy(ra[e .. _length], ra[s .. newlen]);
                    foreach(k, rx; ra[s .. newlen]) {
                        rx.index!N._index = s+k;
                    }
                    fill(ra[newlen .. _length], cast(ThisNode*) null);
                    _length -= e-s;
                }else {
                    // maybe not contiguous
                    // need to be efficient with moving chunks
                    auto arr = allocatedArray!Allocator(r);
                    sort!_RemovePred(arr);
                    if(arr.length == 1) _RemoveAll(arr[0].node);
                    else{
                        auto ixs = map!_RemoveUn(arr);
                        auto ab = zip(ixs, chain(drop(ixs, 1), [node_count]));
                        size_t p = ixs.front;
                        foreach(a,b; ab) {
                            auto pstart = p;
                            p += b-a-1;
                            _RemoveAllBut!N(ra[a]);
                            dealloc(ra[a]);
                            copy(ra[a+1 .. b], ra[pstart .. p]);
                            foreach(k, n; arr[pstart .. p])
                                n.node.index!N._index = pstart+k;
                        }
                        fill(ra[p .. $], cast(ThisNode*) null);
                    }
                    foreach(p; arr) p.obliterated = true;
                }
                return RARange(this, 0, 0);
            }

            void _NodeReplace(ThisNode* old, ThisNode* newnode) {
                move(newnode, ra[old.index!N._index]);
                newnode.index!N._index = old.index!N._index;
            }

            void _Check(){
                foreach(i, n; ra[0 .. node_count]) {
                    assert(n.index!N._index == i);
                }
            }

            string toString0(){
                string r = "[";
                auto rng = opSlice();
                while(!rng.empty){
                    r ~= format("%s", rng.front);
                    rng.popFront();
                    r ~= rng.empty ? "]" : ", ";
                }
                return r;
            }

            private RARange fromNode(ThisNode* n){
                size_t ix = n.index!N._index;
                return RARange(this, ix, this.node_count);
            }
        }
    }
}

// RBTree node impl. taken from std.container - that's Steven Schveighoffer's
// code - and modified to suit.

/**
 * Enumeration determining what color the node is.  Null nodes are assumed
 * to be black.
 */
enum Color : byte
{
    Red,
    Black
}

/// ordered node implementation
mixin template OrderedNodeMixin(size_t N){
    alias typeof(this)* Node;
    Node _left;
    Node _right;

version(PtrHackery){
    size_t _p;

    @property void _parent(Node p){
        Color c = color;
        _p = cast(size_t) p;
        color = c;
    }
    @property Node _parent(){
        size_t r = _p;
        btr(&r,0);
        return cast(Node) r;
    }

    @property void color(Color c){
        if(c) bts(&_p,0);
        else btr(&_p,0);
    }
    @property Color color(){
        return cast(Color) bt(&_p,0);
    }
}else{
    Node _parent;
    /**
     * The color of the node.
     */
    Color color;
}

    /**
     * Get the left child
     */
    @property inout(typeof(this))* left() inout
    {
        return _left;
    }

    /**
     * Get the right child
     */
    @property inout(typeof(this))* right() inout
    {
        return _right;
    }

    /**
     * Get the parent
     */
    @property Node parent()
    {
        return _parent;
    }

    /**
     * Set the left child.  Also updates the new child's parent node.  This
     * does not update the previous child.
     *
     * Returns newNode
     */
    @property Node left(Node newNode)
    {
        _left = newNode;
        if(newNode !is null)
            newNode.index!N._parent = &this;
        return newNode;
    }

    /**
     * Set the right child.  Also updates the new child's parent node.  This
     * does not update the previous child.
     *
     * Returns newNode
     */
    @property Node right(Node newNode)
    {
        _right = newNode;
        if(newNode !is null)
            newNode.index!N._parent = &this;
        return newNode;
    }

    // assume _left is not null
    //
    // performs rotate-right operation, where this is T, _right is R, _left is
    // L, _parent is P:
    //
    //      P         P
    //      |   ->    |
    //      T         L
    //     / \       / \
    //    L   R     a   T
    //   / \           / \
    //  a   b         b   R
    //
    /**
     * Rotate right.  This performs the following operations:
     *  - The left child becomes the parent of this node.
     *  - This node becomes the new parent's right child.
     *  - The old right child of the new parent becomes the left child of this
     *    node.
     */
    Node rotateR()
        in
        {
            assert(_left !is null);
        }
    body
    {
        // sets _left._parent also
        if(isLeftNode)
            parent.index!N.left = _left;
        else
            parent.index!N.right = _left;
        Node tmp = _left.index!N._right;

        // sets _parent also
        _left.index!N.right = &this;

        // sets tmp._parent also
        left = tmp;

        return &this;
    }

    // assumes _right is non null
    //
    // performs rotate-left operation, where this is T, _right is R, _left is
    // L, _parent is P:
    //
    //      P           P
    //      |    ->     |
    //      T           R
    //     / \         / \
    //    L   R       T   b
    //       / \     / \
    //      a   b   L   a
    //
    /**
     * Rotate left.  This performs the following operations:
     *  - The right child becomes the parent of this node.
     *  - This node becomes the new parent's left child.
     *  - The old left child of the new parent becomes the right child of this
     *    node.
     */
    Node rotateL()
        in
        {
            assert(_right !is null);
        }
    body
    {
        // sets _right._parent also
        if(isLeftNode)
            parent.index!N.left = _right;
        else
            parent.index!N.right = _right;
        Node tmp = _right.index!N._left;

        // sets _parent also
        _right.index!N.left = &this;

        // sets tmp._parent also
        right = tmp;
        return &this;
    }


    /**
     * Returns true if this node is a left child.
     *
     * Note that this should always return a value because the root has a
     * parent which is the marker node.
     */
    @property bool isLeftNode() const
        in
        {
            assert(_parent !is null);
        }
    body
    {
        return _parent.index!N._left is &this;
    }

    /**
     * Set the color of the node after it is inserted.  This performs an
     * update to the whole tree, possibly rotating nodes to keep the Red-Black
     * properties correct.  This is an O(lg(n)) operation, where n is the
     * number of nodes in the tree.
     *
     * end is the marker node, which is the parent of the topmost valid node.
     */
    void setColor(Node end)
    {
        // test against the marker node
        if(_parent !is end)
        {
            if(_parent.index!N.color == Color.Red)
            {
                Node cur = &this;
                while(true)
                {
                    // because root is always black, _parent._parent always exists
                    if(cur.index!N._parent.index!N.isLeftNode)
                    {
                        // parent is left node, y is 'uncle', could be null
                        Node y = cur.index!N._parent.index!N._parent.index!N._right;
                        if(y !is null && y.index!N.color == Color.Red)
                        {
                            cur.index!N._parent.index!N.color = Color.Black;
                            y.index!N.color = Color.Black;
                            cur = cur.index!N._parent.index!N._parent;
                            if(cur.index!N._parent is end)
                            {
                                // root node
                                cur.index!N.color = Color.Black;
                                break;
                            }
                            else
                            {
                                // not root node
                                cur.index!N.color = Color.Red;
                                if(cur.index!N._parent.index!N.color == Color.Black)
                                    // satisfied, exit the loop
                                    break;
                            }
                        }
                        else
                        {
                            if(!cur.index!N.isLeftNode)
                                cur = cur.index!N._parent.index!N.rotateL();
                            cur.index!N._parent.index!N.color = Color.Black;
                            cur = cur.index!N._parent.index!N._parent.index!N.rotateR();
                            cur.index!N.color = Color.Red;
                            // tree should be satisfied now
                            break;
                        }
                    }
                    else
                    {
                        // parent is right node, y is 'uncle'
                        Node y = cur.index!N._parent.index!N._parent.index!N._left;
                        if(y !is null && y.index!N.color == Color.Red)
                        {
                            cur.index!N._parent.index!N.color = Color.Black;
                            y.index!N.color = Color.Black;
                            cur = cur.index!N._parent.index!N._parent;
                            if(cur.index!N._parent is end)
                            {
                                // root node
                                cur.index!N.color = Color.Black;
                                break;
                            }
                            else
                            {
                                // not root node
                                cur.index!N.color = Color.Red;
                                if(cur.index!N._parent.index!N.color == Color.Black)
                                    // satisfied, exit the loop
                                    break;
                            }
                        }
                        else
                        {
                            if(cur.index!N.isLeftNode)
                                cur = cur.index!N._parent.index!N.rotateR();
                            cur.index!N._parent.index!N.color = Color.Black;
                            cur = cur.index!N._parent.index!N._parent.index!N.rotateL();
                            cur.index!N.color = Color.Red;
                            // tree should be satisfied now
                            break;
                        }
                    }
                }

            }
        }
        else
        {
            //
            // this is the root node, color it black
            //
            color = Color.Black;
        }
    }

    /**
     * Remove this node from the tree.  The 'end' node is used as the marker
     * which is root's parent.  Note that this cannot be null!
     *
     * Returns the next highest valued node in the tree after this one, or end
     * if this was the highest-valued node.
     */
    Node remove(Node end)
    {
        //
        // remove this node from the tree, fixing the color if necessary.
        //
        Node x;
        Node ret;
        if(_left is null || _right is null)
        {
            ret = next;
        }
        else
        {
            //
            // normally, we can just swap this node's and y's value, but
            // because an iterator could be pointing to y and we don't want to
            // disturb it, we swap this node and y's structure instead.  This
            // can also be a benefit if the value of the tree is a large
            // struct, which takes a long time to copy.
            //
            Node yp, yl, yr;
            Node y = next;
            yp = y.index!N._parent;
            yl = y.index!N._left;
            yr = y.index!N._right;
            auto yc = y.index!N.color;
            auto isyleft = y.index!N.isLeftNode;

            //
            // replace y's structure with structure of this node.
            //
            if(isLeftNode)
                _parent.index!N.left = y;
            else
                _parent.index!N.right = y;
            //
            // need special case so y doesn't point back to itself
            //
            y.index!N.left = _left;
            if(_right is y)
                y.index!N.right = &this;
            else
                y.index!N.right = _right;
            y.index!N.color = color;

            //
            // replace this node's structure with structure of y.
            //
            left = yl;
            right = yr;
            if(_parent !is y)
            {
                if(isyleft)
                    yp.index!N.left = &this;
                else
                    yp.index!N.right = &this;
            }
            color = yc;

            //
            // set return value
            //
            ret = y;
        }

        // if this has less than 2 children, remove it
        if(_left !is null)
            x = _left;
        else
            x = _right;

        // remove this from the tree at the end of the procedure
        bool removeThis = false;
        if(x is null)
        {
            // pretend this is a null node, remove this on finishing
            x = &this;
            removeThis = true;
        }
        else if(isLeftNode)
            _parent.index!N.left = x;
        else
            _parent.index!N.right = x;

        // if the color of this is black, then it needs to be fixed
        if(color == color.Black)
        {
            // need to recolor the tree.
            while(x.index!N._parent !is end && x.index!N.color == Color.Black)
            {
                if(x.index!N.isLeftNode)
                {
                    // left node
                    Node w = x.index!N._parent.index!N._right;
                    if(w.index!N.color == Color.Red)
                    {
                        w.index!N.color = Color.Black;
                        x.index!N._parent.index!N.color = Color.Red;
                        x.index!N._parent.index!N.rotateL();
                        w = x.index!N._parent.index!N._right;
                    }
                    Node wl = w.index!N.left;
                    Node wr = w.index!N.right;
                    if((wl is null || wl.index!N.color == Color.Black) &&
                            (wr is null || wr.index!N.color == Color.Black))
                    {
                        w.index!N.color = Color.Red;
                        x = x.index!N._parent;
                    }
                    else
                    {
                        if(wr is null || wr.index!N.color == Color.Black)
                        {
                            // wl cannot be null here
                            wl.index!N.color = Color.Black;
                            w.index!N.color = Color.Red;
                            w.index!N.rotateR();
                            w = x.index!N._parent.index!N._right;
                        }

                        w.index!N.color = x.index!N._parent.index!N.color;
                        x.index!N._parent.index!N.color = Color.Black;
                        w.index!N._right.index!N.color = Color.Black;
                        x.index!N._parent.index!N.rotateL();
                        x = end.index!N.left; // x = root
                    }
                }
                else
                {
                    // right node
                    Node w = x.index!N._parent.index!N._left;
                    if(w.index!N.color == Color.Red)
                    {
                        w.index!N.color = Color.Black;
                        x.index!N._parent.index!N.color = Color.Red;
                        x.index!N._parent.index!N.rotateR();
                        w = x.index!N._parent.index!N._left;
                    }
                    Node wl = w.index!N.left;
                    Node wr = w.index!N.right;
                    if((wl is null || wl.index!N.color == Color.Black) &&
                            (wr is null || wr.index!N.color == Color.Black))
                    {
                        w.index!N.color = Color.Red;
                        x = x.index!N._parent;
                    }
                    else
                    {
                        if(wl is null || wl.index!N.color == Color.Black)
                        {
                            // wr cannot be null here
                            wr.index!N.color = Color.Black;
                            w.index!N.color = Color.Red;
                            w.index!N.rotateL();
                            w = x.index!N._parent.index!N._left;
                        }

                        w.index!N.color = x.index!N._parent.index!N.color;
                        x.index!N._parent.index!N.color = Color.Black;
                        w.index!N._left.index!N.color = Color.Black;
                        x.index!N._parent.index!N.rotateR();
                        x = end.index!N.left; // x = root
                    }
                }
            }
            x.index!N.color = Color.Black;
        }

        if(removeThis)
        {
            //
            // clear this node out of the tree
            //
            if(isLeftNode)
                _parent.index!N.left = null;
            else
                _parent.index!N.right = null;
        }

        return ret;
    }

    /**
     * Return the leftmost descendant of this node.
     */
    @property leftmost() inout
    {
        typeof(this)* result = &this;
        while(result.index!N._left !is null)
            result = result.index!N._left;
        return result;
    }

    /**
     * Return the rightmost descendant of this node
     */
    @property rightmost() inout
    {
        auto result = &this;
        while(result.index!N._right !is null)
            result = result.index!N._right;
        return result;
    }

    @property parentmost() inout
    {
        auto result = &this;
        while(result.index!N._parent !is null)
            result = result.index!N._parent;
        return result;
    }

    /**
     * Returns the next valued node in the tree.
     *
     * You should never call this on the marker node, as it is assumed that
     * there is a valid next node.
     */
    @property inout(typeof(this))* next() inout
    in{
        debug assert( &this !is this.index!N.parentmost.index!N.rightmost,
            "calling prev on _end.rightmost");
    }body{
        auto n = &this;
        if(n.index!N.right is null)
        {
            while(!n.index!N.isLeftNode)
                n = n.index!N._parent;
            return n.index!N._parent;
        }
        else
            return n.index!N.right.index!N.leftmost;
    }

    /**
     * Returns the previous valued node in the tree.
     *
     * You should never call this on the leftmost node of the tree as it is
     * assumed that there is a valid previous node.
     */
    @property inout(typeof(this))* prev() inout
    in{
        debug assert( &this !is this.index!N.parentmost.index!N.leftmost,
            "calling prev on _end.leftmost");
    }body{
        auto n = &this;
        if(n.index!N.left is null)
        {
            while(n.index!N.isLeftNode)
                n = n.index!N._parent;
            n = n.index!N._parent;
            return n;
        }
        else
            return n.index!N.left.index!N.rightmost;
    }

}

/// ordered index implementation
mixin template OrderedIndex(size_t N, bool allowDuplicates, alias KeyFromValue, alias Compare, ThisContainer) {
    // this index does do memory allocation
    // 1) in removeKey, moves stuff to allocated array
    // 2) somewhere does new Exception(...)
    alias ThisNode* Node;
    alias binaryFun!Compare _less;
    alias unaryFun!KeyFromValue key;
    alias typeof(key(Value.init)) KeyType;

    /**
     * The range type for this index, which embodies a bidirectional range
     */
    struct OrderedRangeT(bool is_const)
    {
        static if(is_const) {
            alias const(ThisNode) Node;
            alias const(ThisContainer) Container;
        }else {
            alias ThisContainer Container;
            alias ThisNode Node;
        }
        Container c;
        private Node* _begin;
        private Node* _end;

        this(Container _c, Node* b, Node* e) {
            c = _c;
            _begin = b;
            _end = e;
        }

        /**
         * Returns $(D true) if the range is _empty
         */
        @property bool empty() const
        {
            return _begin is _end;
        }

        @property front_node() {
            return _begin;
        };

        @property back_node() {
            return _end.index!N.prev;
        }
        /**
         * Returns the first element in the range
         */
        @property front()
        {
            return front_node.value;
        }

        /**
         * Returns the last element in the range
         */
        @property back()
        {
            return back_node.value;
        }

        /**
         * pop the front element from the range
         *
         * complexity: amortized $(BIGOH 1)
         */
        void popFront()
        {
            _begin = _begin.index!N.next;
        }

        /**
         * pop the back element from the range
         *
         * complexity: amortized $(BIGOH 1)
         */
        void popBack()
        {
            _end = _end.index!N.prev;
        }

        /**
         * Trivial _save implementation, needed for $(D isForwardRange).
         */
        @property save()
        {
            return this;
        }
    }

    alias OrderedRangeT!true ConstOrderedRange;
    alias OrderedRangeT!false OrderedRange;

    template IsMyRange(T) {
        enum bool IsMyRange =
            is(T == OrderedRange) ||
            is(T == ConstOrderedRange);
    }

    auto _add(Node n)
    {
        bool added = true;

        if(!_end.index!N.left)
        {
            _end.index!N.left = n;
        }
        else
        {
            Node newParent = _end.index!N.left;
            Node nxt = void;
            auto k = key(n.value);
            while(true)
            {
                auto pk = key(newParent.value);
                if(_less(k, pk))
                {
                    nxt = newParent.index!N.left;
                    if(nxt is null)
                    {
                        //
                        // add to right of new parent
                        //
                        newParent.index!N.left = n;
                        break;
                    }
                }
                else
                {
                    static if(!allowDuplicates)
                    {
                        if(!_less(pk, k))
                        {
                            added = false;
                            break;
                        }
                    }
                    nxt = newParent.index!N.right;
                    if(nxt is null)
                    {
                        //
                        // add to right of new parent
                        //
                        newParent.index!N.right = n;
                        break;
                    }
                }
                newParent = nxt;
            }
        }

        static if(allowDuplicates)
        {
            n.index!N.setColor(_end);
            version(RBDoChecks) _Check();
            return added;
        }
        else
        {
            if(added)
                n.index!N.setColor(_end);
            version(RBDoChecks) _Check();
            return added;
        }
    }

    /**
     * Element type for the tree
     */
    alias ValueView Elem;

    Node   _end;

    static if(!allowDuplicates){
        bool _DenyInsertion(Node n, out Node cursor){
            return _find2(key(n.value), cursor);
        }
    }

    static if(allowDuplicates) alias _add _Insert;
    else void _Insert(Node n, Node cursor){
        if(cursor !is null){
            if (_less(key(n.value), key(cursor.value))){
                cursor.index!N.left = n;
            }else{
                cursor.index!N.right = n;
            }
            n.index!N.setColor(_end);
        }else{
            _add(n);
        }

    }


    // if k exists in this index, returns par such that eq(key(par.value),k),
    // and returns true
    // if k !exists in this index, returns par such that k value belongs either
    // as par.left or par.right. remember to setColor! returns false.
    private bool _find2(KeyType k, out inout(ThisNode)* par) inout
    {
        auto cur = _end.index!N.left;
        par = null;
        while(cur)
        {
            // BAD!!! TODO: figure out unaryFun & inout
            auto ck = key(cast() cur.value);
            par = cur;
            if(_less(ck, k)){
                cur = cur.index!N.right;
            }else if(_less(k, ck)){
                cur = cur.index!N.left;
            }else{
                return true;
            }
        }
        return false;
    }

    private bool _find2At(KeyType k, Node cur, out Node par)
    {
        par = null;
        while(cur)
        {
            auto ck = key(cur.value);
            par = cur;
            if(_less(ck, k)){
                cur = cur.index!N.right;
            }else if(_less(k, ck)){
                cur = cur.index!N.left;
            }else{
                return true;
            }
        }
        return false;
    }

    /**
     * Check if any elements exist in the container.  Returns $(D true) if at least
     * one element exists.
     * Complexity: $(BIGOH 1)
     */
    @property bool empty() const
    {
        return node_count == 0;
    }

/++
Returns the number of elements in the container.

Complexity: $(BIGOH 1).
+/
        @property size_t length() const
        {
            return node_count;
        }

    /**
     * Fetch a range that spans all the elements in the container.
     *
     * Complexity: $(BIGOH log(n))
     */
    OrderedRange opSlice()
    {
        return OrderedRange(this,_end.index!N.leftmost, _end);
    }

    ConstOrderedRange opSlice() const{
        return ConstOrderedRange(this,_end.index!N.leftmost, _end);
    }

    /**
     * The front element in the container
     *
     * Complexity: $(BIGOH log(n))
     */
    @property front() inout
    {
        return _end.index!N.leftmost.value;
    }

    /**
     * The last element in the container
     *
     * Complexity: $(BIGOH log(n))
     */
    @property back() inout
    {
        return _end.index!N.prev.value;
    }

    /++
        $(D in) operator. Check to see if the given element exists in the
        container.

        Complexity: $(BIGOH log(n))
        +/
        bool opBinaryRight(string op)(Elem e) const
        if (op == "in")
        {
            const(ThisNode)* p;
            return _find2(key(e),p);
        }
    /++
        $(D in) operator. Check to see if the given element exists in the
        container.

        Complexity: $(BIGOH log(n))
        +/
        static if(!isImplicitlyConvertible!(KeyType, Elem)){
            bool opBinaryRight(string op,K)(K k) if (op == "in" &&
                    isImplicitlyConvertible!(K, KeyType))
            {
                Node p;
                return _find2(k,p);
            }
        }

    void _ClearIndex() {
        _end.index!N._left = null;
    }

    /**
     * Removes all elements from the container.
     *
     * Complexity: ??
     */
    void clear()
    {
        _Clear();
    }

    static if(!allowDuplicates){
/**
Available for Unique variant.
Complexity:
$(BIGOH log(n))
*/
        ValueView opIndex(KeyType k) inout{
            inout(ThisNode)* n;
            enforce(_find2(k,n));
            return cast(ValueView) n.value;
        }
    }

/**
Perform mod on r.front and performs any necessary fixups to container's
indices. If the result of mod violates any index' invariant, r.front is
removed from the container.
Preconditions: !r.empty, $(BR)
mod is a callable of the form void mod(ref Value)
Complexity: $(BIGOH m(n)), $(BR) $(BIGOH log(n)) for this index
*/

    void modify(SomeRange, Modifier)(SomeRange r, Modifier mod)
    if(is(SomeRange == OrderedRange) ||
       is(ElementType!SomeRange == Position!ThisNode)) {
        while(!r.empty) {
            static if(is(SomeRange == OrderedRange)) {
                Node node = r.front_node;
            }else {
                Node node = r.front.node;
            }
            r.popFront();
            _Modify(node, mod);
        }
    }
/**
Replaces r.front with value
Returns: whether replacement succeeded
Complexity: ??
*/
    bool replace(Position!ThisNode r, ValueView value) {
        return _Replace(r.node, cast(Value) value);
    }

    KeyType _NodePosition(ThisNode* node){
        return key(node.value);
    }

    // cursor = null -> no fixup needed
    // cursor != null -> fixup needed
    bool _PositionFixable(ThisNode* node, KeyType oldPosition,
            out ThisNode* cursor){
        cursor = null;
        // case 1: key hasn't changed
        auto newPosition = key(node.value);
        if(!_less(newPosition, oldPosition) &&
           !_less(oldPosition, newPosition)) return true;
        Node next = _end.index!N.rightmost is node ? null : node.index!N.next;
        auto prev = _end.index!N.leftmost is node ? null : node.index!N.prev;

        // case 2: key has changed, but relative position hasn't
        bool outOfBounds = (next && next != _end &&
                !_less(newPosition, key(next.value))) ||
            prev && !_less(key(prev.value), newPosition);
        if (!outOfBounds) return true;

        // case 3: key has changed, position has changed
        static if(allowDuplicates){
            cursor = node;
            return true;
        }else{
            bool found = _find2(newPosition, cursor);
            if(cursor is node){
                // node's old value is in path to node's new value
                if(_less(newPosition, oldPosition)){
                    if(cursor.index!N._left){
                        found = _find2At(newPosition,
                                cursor.index!N._left, cursor);
                    }else{
                        found = false;
                    }
                }else{
                    if(cursor.index!N._right){
                        found = _find2At(newPosition,
                                cursor.index!N._right, cursor);
                    }else{
                        found = false;
                    }
                }
            }
            return !found;
        }
    }

    void _FixPosition(ThisNode* node, KeyType oldPosition, ThisNode* cursor)
        out{
            version(RBDoChecks) _Check();
        }body{
        static if(allowDuplicates){
            if(cursor){
                _Remove(node);
                node.index!N._parent =
                    node.index!N._left =
                    node.index!N._right = null;
                node.index!N.color = Color.Red;
                _Insert(node);
            }
        }else{
            if(!cursor) return;
            _Remove(node);
            node.index!N._parent =
                node.index!N._left =
                node.index!N._right = null;
            node.index!N.color = Color.Red;
            _Insert(node, cursor);
        }
    }

    // n's value has changed and its position might be invalid.
    // remove n if it violates an invariant.
    // returns: true iff n's validity has been restored
    bool _NotifyChange(Node node)
    out(r){
        _Check();
    }body{
        auto newPosition = key(node.value);
        Node next = _end.index!N.rightmost is node ? null : node.index!N.next;
        Node prev = _end.index!N.leftmost  is node ? null : node.index!N.prev;

        // case 1: key has changed, but relative position hasn't
        bool outOfBounds = (next && next != _end &&
                !_less(newPosition, key(next.value))) ||
            prev && !_less(key(prev.value), newPosition);
        if (!outOfBounds) return true;

        // case 2: key has changed, position has changed
        static if(allowDuplicates){
            _Remove(node);
            node.index!N._parent =
                node.index!N._left =
                node.index!N._right = null;
            node.index!N.color = Color.Red;
            _Insert(node);
            return true;
        }else{
            Node cursor;
            _Remove(node);
            bool found = _find2(newPosition, cursor);
            if(found){
                _RemoveAllBut!N(node);
                return false;
            }
            node.index!N._parent =
                node.index!N._left =
                node.index!N._right = null;
            node.index!N.color = Color.Red;
            _Insert(node, cursor);
            return true;
        }
    }

    /**
     * Insert a single element in the container.  Note that this does not
     * invalidate any ranges currently iterating the container.
     *
     * Complexity: $(BIGOH i(n)); $(BR) $(BIGOH log(n)) for this index
     */
    size_t insert(Stuff)(Stuff stuff)
        if (isImplicitlyConvertible!(Stuff, Elem))
        out(r){
            version(RBDoChecks) _Check();
        }body{
            static if(!allowDuplicates){
                Node p;
                if(_find2(key(stuff),p)){
                    return 0;
                }
            }
            Node n = _InsertAllBut!N(stuff);
            if(!n) return 0;
            static if(!allowDuplicates){
                _Insert(n,p);
            }else _add(n);
            return 1;
        }

    /**
     * Insert a range of elements in the container.  Note that this does not
     * invalidate any ranges currently iterating the container.
     *
     * Complexity: $(BIGOH n $(SUB stuff) * i(n)); $(BR) $(BIGOH n $(SUB
     stuff) * log(n)) for this index
     */
    size_t insert(Stuff)(Stuff stuff)
        if(isInputRange!Stuff &&
                isImplicitlyConvertible!(ElementType!Stuff, Elem))
        out(r){
            version(RBDoChecks) _Check();
        }body{
            size_t result = 0;
            foreach(e; stuff)
            {
                result += insert(e);
            }
            return result;
        }

    Node _Remove(Node n)
    out(r){
        version(RBDoChecks) _Check();
    }body{
        return n.index!N.remove(_end);
    }

    /**
     * Remove an element from the container and return its value.
     *
     * Complexity: $(BIGOH d(n)); $(BR) $(BIGOH log(n)) for this index
     */
    Elem removeAny() {
        auto n = _end.index!N.leftmost;
        auto result = n.value;
        _RemoveAll(n);
        return result;
    }

    /**
     * Remove the front element from the container.
     *
     * Complexity: $(BIGOH d(n)); $(BR) $(BIGOH log(n)) for this index
     */
    void removeFront() {
        auto n = _end.index!N.leftmost;
        _RemoveAll(n);
    }

    /**
     * Remove the back element from the container.
     *
     * Complexity: $(BIGOH d(n)); $(BR) $(BIGOH log(n)) for this index
     */
    void removeBack() {
        auto n = _end.index!N.prev;
        _RemoveAll(n);
    }

    /++
        Removes the given range from the container.

        Returns: A range containing all of the elements that were after the
        given range.

        Complexity:$(BIGOH n $(SUB r) * d(n)); $(BR) $(BIGOH n $(SUB r) *
                log(n)) for this index
    +/
    OrderedRange remove(R)(R r)
    if(is(R == OrderedRange) ||
       is(ElementType!R == Position!ThisNode))
    out(r2){
        version(RBDoChecks) _Check();
    }body{
        while(!r.empty) {
            static if(is(R == OrderedRange)) {
                auto node = r.front_node;
            }else{
                auto node = r.front.node;
                r.front.obliterated = true;
            }
            r.popFront();
            _RemoveAll!N(node);
        }
        return OrderedRange(this, _end, _end);
    }

    /++
   Removes elements from the container that are equal to the given values
   according to the less comparator. One element is removed for each value
   given which is in the container. If $(D allowDuplicates) is true,
   duplicates are removed only if duplicate values are given.

   Returns: The number of elements removed.

   Complexity: $(BIGOH n $(SUB keys) d(n)); $(BR) $(BIGOH n
   $(SUB keys) log(n)) for this index

   Examples:
    --------------------
    // ya, this needs updating
    auto rbt = redBlackTree!true(0, 1, 1, 1, 4, 5, 7);
    rbt.removeKey(1, 4, 7);
    assert(std.algorithm.equal(rbt[], [0, 1, 1, 5]));
    rbt.removeKey(1, 1, 0);
    assert(std.algorithm.equal(rbt[], [5]));
    --------------------
    +/
    size_t removeKey(Keys...)(Keys keys)
    if(allSatisfy!(implicitlyConverts,Keys))
    out(r){
        version(RBDoChecks) _Check();
    }body{
        // stack allocation - is ok
        Unqual!KeyType[Keys.length] toRemove;
        foreach(i,k; keys) {
            Unqual!KeyType k2 = k;
            move(k2, toRemove[i]);
        }

        return removeKey(cast(KeyType[])(toRemove[]));
    }

    size_t removeKey(Key)(Key[] keys)
    if(isImplicitlyConvertible!(Key, KeyType))
    out(r){
        version(RBDoChecks) _Check();
    }body{
        size_t count = 0;

        foreach(k; keys)
        {
            auto beg = _firstGreaterEqual(k);
            if(beg is _end || _less(k, key(beg.value)))
                // no values are equal
                continue;
            _RemoveAll(beg);
            count++;
        }

        return count;
    }

    private template implicitlyConverts(Key){
        enum implicitlyConverts = isImplicitlyConvertible!(Key,KeyType);
    }

    /++ Ditto +/
    size_t removeKey(Stuff)(Stuff stuff)
    if(isInputRange!Stuff &&
            isImplicitlyConvertible!(ElementType!Stuff, KeyType) &&
            !isDynamicArray!Stuff)
    out(r){
        version(RBDoChecks) _Check();
    }body{
        //We use array in case stuff is a Range from this RedBlackTree - either
        //directly or indirectly.

        alias ElementType!Stuff E;

        auto stuffy = allocatedArray!Allocator(stuff);
        auto res = removeKey(stuffy);
        Allocator.deallocate(stuffy.ptr);
        return res;
    }

    // find the first node where the value is > k
    private inout(ThisNode)* _firstGreater(U)(U k) inout
    if(isImplicitlyConvertible!(U, KeyType))
    {
        // can't use _find, because we cannot return null
        typeof(return) cur = _end.index!N.left;
        typeof(return) result = _end;
        while(cur)
        {
            // TODO: figure out unaryFun & inout
            if(_less(k, key(cast() cur.value)))
            {
                result = cur;
                cur = cur.index!N.left;
            }
            else
                cur = cur.index!N.right;
        }
        return result;
    }
    private inout(ThisNode)*
        _firstGreater(CompatibleLess, CompatibleKey)
        (CompatibleKey k) inout {
        // can't use _find, because we cannot return null
        typeof(return) cur = _end.index!N.left;
        typeof(return) result = _end;
        while(cur)
        {
            // TODO: figure out unaryFun & inout
            if(CompatibleLess.ck_less(k, key(cast() cur.value)))
            {
                result = cur;
                cur = cur.index!N.left;
            }
            else
                cur = cur.index!N.right;
        }
        return result;
    }

    // find the first node where the value is >= k
    private inout(ThisNode)* _firstGreaterEqual(U)(U k) inout
    if(isImplicitlyConvertible!(U, KeyType))
    {
        // can't use _find, because we cannot return null.
        typeof(return) cur = _end.index!N.left;
        typeof(return) result = _end;
        while(cur)
        {
            // TODO: figure out unaryFun & inout
            if(_less(key(cast() cur.value), k))
                cur = cur.index!N.right;
            else
            {
                result = cur;
                cur = cur.index!N.left;
            }

        }
        return result;
    }

    // find the first node where the value is >= k
    private inout(ThisNode)*
        _firstGreaterEqual(CompatibleLess, CompatibleKey)
        (CompatibleKey k) inout {
        // can't use _find, because we cannot return null.
        typeof(return) cur = _end.index!N.left;
        typeof(return) result = _end;
        while(cur)
        {
            // TODO: figure out unaryFun & inout
            if(CompatibleLess.kc_less(key(cast() cur.value), k))
                cur = cur.index!N.right;
            else
            {
                result = cur;
                cur = cur.index!N.left;
            }

        }
        return result;
    }

    /**
     * Get a range from the container with all elements that are > k according
     * to the less comparator
     *
     * Complexity: $(BIGOH log(n))
     */
    auto upperBound(U)(U k)
    if(isImplicitlyConvertible!(U, KeyType))
    {
        return OrderedRange(this,_firstGreater(k), _end);
    }
    auto upperBound(U)(U k) const
    if(isImplicitlyConvertible!(U, KeyType))
    {
        return ConstOrderedRange(this,_firstGreater(k), _end);
    }
    auto upperBound(CompatibleLess, CompatibleKey)(CompatibleKey k)
    {
        return OrderedRange(this,_firstGreater!CompatibleLess(k), _end);
    }
    auto upperBound(CompatibleLess, CompatibleKey)(CompatibleKey k) const
    {
        return ConstOrderedRange(this,_firstGreater!CompatibleLess(k), _end);
    }

    /**
     * Get a range from the container with all elements that are < k according
     * to the less comparator
     *
     * Complexity: $(BIGOH log(n))
     */
    auto lowerBound(U)(U k)
    if(isImplicitlyConvertible!(U, KeyType))
    {
        return OrderedRange(this,_end.index!N.leftmost, _firstGreaterEqual(k));
    }
    auto lowerBound(U)(U k) const
    if(isImplicitlyConvertible!(U, KeyType))
    {
        return ConstOrderedRange(this,_end.index!N.leftmost, _firstGreaterEqual(k));
    }

    auto lowerBound(CompatibleLess, CompatibleKey)(CompatibleKey k)
    {
        return OrderedRange(this,_end.index!N.leftmost,
                _firstGreaterEqual!CompatibleLess(k));
    }
    auto lowerBound(CompatibleLess, CompatibleKey)(CompatibleKey k) const
    {
        return ConstOrderedRange(this,_end.index!N.leftmost,
                _firstGreaterEqual!CompatibleLess(k));
    }

    /**
     * Get a range from the container with all elements that are == k according
     * to the less comparator
     *
     * Complexity: $(BIGOH log(n))
     */
    // TODO: compact these back into one
    auto equalRange(U)(U k)
    if(isImplicitlyConvertible!(U, KeyType))
    {
        auto beg = _firstGreaterEqual(k);
        if(beg is _end || _less(k, key(beg.value)))
            // no values are equal
            return OrderedRange(this,beg, beg);
        static if(allowDuplicates)
        {
            return OrderedRange(this,beg, _firstGreater(k));
        }
        else
        {
            // no sense in doing a full search, no duplicates are allowed,
            // so we just get the next node.
            return OrderedRange(this,beg, beg.index!N.next);
        }
    }
    auto equalRange(U)(U k) const
    if(isImplicitlyConvertible!(U, KeyType))
    {
        auto beg = _firstGreaterEqual(k);
        if(beg is _end || _less(k, key(beg.value)))
            // no values are equal
            return ConstOrderedRange(this,beg, beg);
        static if(allowDuplicates)
        {
            return ConstOrderedRange(this,beg, _firstGreater(k));
        }
        else
        {
            // no sense in doing a full search, no duplicates are allowed,
            // so we just get the next node.
            return ConstOrderedRange(this,beg, beg.index!N.next);
        }
    }

    // @@@BUG@@@ dmd issue 8440 prevents us frem naming this function equalRange
    OrderedRange cEqualRange(CompatibleLess, CompatibleKey)(CompatibleKey k)
    if(IsCompatibleLess!(CompatibleLess, KeyType, CompatibleKey))
    {
        auto beg = _firstGreaterEqual!CompatibleLess(k);
        if(beg is _end || CompatibleLess.ck_less(k, key(beg.value)))
            // no values are equal
            return OrderedRange(this,beg, beg);
        return OrderedRange(this,beg, _firstGreater!CompatibleLess(k));
    }
    ConstOrderedRange cEqualRange(CompatibleLess, CompatibleKey)(CompatibleKey k) const
    if(IsCompatibleLess!(CompatibleLess, KeyType, CompatibleKey))
    {
        auto beg = _firstGreaterEqual!CompatibleLess(k);
        if(beg is _end || CompatibleLess.ck_less(k, key(beg.value)))
            // no values are equal
            return ConstOrderedRange(this,beg, beg);
        return ConstOrderedRange(this,beg, _firstGreater!CompatibleLess(k));
    }

/++
Get a range of values bounded below by lower and above by upper, with
inclusiveness defined by boundaries.
Complexity: $(BIGOH log(n))
+/
    auto bounds(string boundaries = "[]", U)(U lower, U upper)
    if(isImplicitlyConvertible!(U, KeyType))
    in{
        static if(boundaries == "[]") assert(!_less(upper,lower),
                format("nonsensical bounds %s%s,%s%s",
                    boundaries[0], lower, upper, boundaries[1]));
        else assert(_less(lower,upper),
                format("nonsensical bounds %s%s,%s%s",
                    boundaries[0], lower, upper, boundaries[1]));
    }body{
        static if(boundaries[0] == '[') {
            auto n_lower = _firstGreaterEqual(lower);
        }else static if(boundaries[0] == '('){
            auto n_lower = _firstGreater(lower);
        }else static assert(false);
        static if(boundaries[1] == ']') {
            auto n_upper = _firstGreater(upper);
        }else static if(boundaries[1] == ')'){
            auto n_upper = _firstGreaterEqual(upper);
        }else static assert(false);
        return OrderedRange(this, n_lower, n_upper);
    }

    auto cbounds(CompatibleLess,string boundaries = "[]", CompatibleKey)
        (CompatibleKey lower, CompatibleKey upper)
    if(IsCompatibleLess!(CompatibleLess, KeyType, CompatibleKey))
    in{
        static if(boundaries == "[]")
            assert(!CompatibleLess.cc_less(upper,lower),
                    format("nonsensical bounds %s%s,%s%s",
                        boundaries[0], lower, upper, boundaries[1]));
        else assert(CompatibleLess.cc_less(lower,upper),
                format("nonsensical bounds %s%s,%s%s",
                    boundaries[0], lower, upper, boundaries[1]));
    }body{
        static if(boundaries[0] == '[') {
            auto n_lower = _firstGreaterEqual!CompatibleLess(lower);
        }else static if(boundaries[0] == '('){
            auto n_lower = _firstGreater!CompatibleLess(lower);
        }else static assert(false);
        static if(boundaries[1] == ']') {
            auto n_upper = _firstGreater!CompatibleLess(upper);
        }else static if(boundaries[1] == ')'){
            auto n_upper = _firstGreaterEqual!CompatibleLess(upper);
        }else static assert(false);
        return OrderedRange(this, n_lower, n_upper);
    }

        /*
         * Print the tree.  This prints a sideways view of the tree in ASCII form,
         * with the number of indentations representing the level of the nodes.
         * It does not print values, only the tree structure and color of nodes.
         */
        void printTree(Node n, int indent = 0)
        {
            if(n !is null)
            {
                printTree(n.index!N.right, indent + 2);
                for(int i = 0; i < indent; i++)
                    write(".");
                write(n.index!N.color == Color.Black ? "B" : "R");
                writefln("(%s)", n.value);
                printTree(n.index!N.left, indent + 2);
            }
            else
            {
                for(int i = 0; i < indent; i++)
                    write(".");
                writeln("N");
            }
            if(indent is 0)
                writeln();
        }
        void _NodeReplace(ThisNode* old, ThisNode* newnode) {
            ThisNode* lch = old.index!N.left;
            ThisNode* rch = old.index!N.right;
            ThisNode* p = old.index!N.parent;

            newnode.index!N.left = lch;
            if(lch) {
                lch.index!N._parent = newnode;
            }
            newnode.index!N.right = rch;
            if(rch) {
                rch.index!N._parent = newnode;
            }
            newnode.index!N._parent = p;
            if(p) {
                if(p.index!N.left is old) {
                    p.index!N.left = newnode;
                }else if(p.index!N.right is old) {
                    p.index!N.right = newnode;
                }
            }else if(old is _end) {
                _end = newnode;
            }

            newnode.index!N.left = null;
            newnode.index!N.right = null;
            newnode.index!N._parent = null;
        }


        /*
         * Check the tree for validity.  This is called after every add or remove.
         * This should only be enabled to debug the implementation of the RB Tree.
         */
        void _Check()
        {
            //
            // check implementation of the tree
            //
            int recurse(Node n, string path)
            {
                if(n is null)
                    return 1;
                if(n.index!N.parent.index!N.left !is n && n.index!N.parent.index!N.right !is n)
                    // memory allocation! ..how to fix?
                    throw new Exception("Node at path " ~ path ~ " has inconsistent pointers");
                Node next = n.index!N.next;
                static if(allowDuplicates)
                {
                    if(next !is _end && _less(key(next.value), key(n.value)))
                        // memory allocation! ..how to fix?
                        throw new Exception("ordering invalid at path " ~ path);
                }
                else
                {
                    if(next !is _end && !_less(key(n.value), key(next.value)))
                        // memory allocation! ..how to fix?
                        throw new Exception("ordering invalid at path " ~ path);
                }
                if(n.index!N.color == Color.Red)
                {
                    if((n.index!N.left !is null && n.index!N.left.index!N.color == Color.Red) ||
                            (n.index!N.right !is null && n.index!N.right.index!N.color == Color.Red))
                        // memory allocation! ..how to fix?
                        throw new Exception("Node at path " ~ path ~ " is red with a red child");
                }

                int l = recurse(n.index!N.left, path ~ "L");
                int r = recurse(n.index!N.right, path ~ "R");
                if(l != r)
                {
                    writeln("bad tree at:");
                    printTree(n);
                    // memory allocation! ..how to fix?
                    throw new Exception("Node at path " ~ path ~ " has different number of black nodes on left and right paths");
                }
                return l + (n.index!N.color == Color.Black ? 1 : 0);
            }

            try
            {
                recurse(_end.index!N.left, "");
            }
            catch(Exception e)
            {
                printTree(_end.index!N.left, 0);
                throw e;
            }
        }

        string toString0(){
            string r = "[";
            auto rng = opSlice();
            while(!rng.empty){
                r ~= format("%s", (rng.front));
                rng.popFront();
                r ~= rng.empty ? "]" : ", ";
            }
            return r;
        }

        private OrderedRange fromNode(ThisNode* n){
            return OrderedRange(this,n, this.index!N._end);
        }
}

/// A red black tree index
template Ordered(bool allowDuplicates = false, alias KeyFromValue="a",
        alias Compare = "a<b") {

    enum bool BenefitsFromSignals = true;

    template Inner(ThisContainer, ThisNode, Value, ValueView, size_t N, Allocator){
        alias TypeTuple!(N, allowDuplicates, KeyFromValue, Compare,ThisContainer) IndexTuple;
        alias OrderedIndex IndexMixin;

        enum IndexCtorMixin = Replace!(q{
            index!($N)._end = Allocator.allocate!ThisNode(1);
        }, "$N", N);
        /// node implementation (ish)
        alias TypeTuple!(N) NodeTuple;
        alias OrderedNodeMixin NodeMixin;
    }
}

/// A red black tree index
template OrderedNonUnique(alias KeyFromValue="a", alias Compare = "a<b") {
    alias Ordered!(true, KeyFromValue, Compare) OrderedNonUnique;
}
/// A red black tree index
template OrderedUnique(alias KeyFromValue="a", alias Compare = "a<b") {
    alias Ordered!(false, KeyFromValue, Compare) OrderedUnique;
}

// end RBTree impl

/// a max heap index
template Heap(alias KeyFromValue = "a", alias Compare = "a<b") {
    // this index allocates the heap array

    enum bool BenefitsFromSignals = true;

    /// _
    template Inner(ThisContainer, ThisNode, Value, ValueView, size_t N, Allocator) {
        alias TypeTuple!() NodeTuple;
        alias TypeTuple!(N,KeyFromValue, Compare, ThisContainer) IndexTuple;

        mixin template NodeMixin(){
            size_t _index;
        }

        /// index implementation
        mixin template IndexMixin(size_t N, alias KeyFromValue, alias Compare,
                ThisContainer){
            alias unaryFun!KeyFromValue key;
            alias binaryFun!Compare less;
            alias typeof(key((Value).init)) KeyType;

            /// The primary range of the index, which embodies a bidirectional
            /// range.
            ///
            /// Ends up performing a breadth first traversal (I think..)
            ///
            /// removeFront and removeBack are not possible.
            struct HeapRangeT(bool is_const) {
                static if(is_const) {
                    alias const(ThisNode) Node;
                    alias const(ThisContainer) Container;
                }else {
                    alias ThisContainer Container;
                    alias ThisNode Node;
                }
                Container c;
                size_t s,e;

                this(Container _c, size_t _s, size_t _e) {
                    c = _c;
                    s = _s;
                    e = _e;
                }

                @property Node* front_node() {
                    return c.index!N._heap[s];
                }

                @property front(){
                    return front_node.value;
                }

                void popFront(){
                    s++;
                }

                @property back_node(){
                    return c.index!N._heap[e-1];
                }

                @property back(){
                    return back_node.value;
                }
                void popBack(){
                    e--;
                }

                @property bool empty()const{
                    assert(e <= c.index!N.length);
                    return s >= c.index!N.length;
                }
                @property size_t length()const{
                    assert(e <= c.index!N.length);
                    return s <= e ? e - s : 0;
                }

                @property save(){ return this; }
            }

            alias HeapRangeT!true ConstHeapRange;
            alias HeapRangeT!false HeapRange;

            template IsMyRange(T) {
                enum bool IsMyRange =
                    is(T == ConstHeapRange) ||
                    is(T == HeapRange);
            }

            ThisNode*[] _heap;

            static size_t p(size_t n) pure{
                return (n-1) / 2;
            }

            static size_t l(size_t n) pure{
                return 2*n + 1;
            }

            static size_t r(size_t n) pure{
                return 2*n + 2;
            }

            void swapAt(size_t n1, size_t n2){
                swap(_heap[n1].index!N._index, _heap[n2].index!N._index);
                swap(_heap[n1], _heap[n2]);
            }

            void sift(size_t n){
                auto k = key(_heap[n].value);
                if(n > 0 && less(key(_heap[p(n)].value), k)){
                    do{
                        swapAt(n, p(n));
                        n = p(n);
                    }while(n > 0 && less(key(_heap[p(n)].value), k));
                }else
                    while(l(n) < node_count){
                        auto ch = l(n);
                        auto lk = key(_heap[ch].value);
                        if(!less(k, lk)) break;
                        if (r(n) < node_count){
                            auto rk = key(_heap[r(n)].value);
                            if(less(lk, rk)){
                                if(!less(k, rk)) break;
                                ch = r(n);
                            }
                        }
                        swapAt(n, ch);
                        n = ch;
                    }
            }

/**
Fetch a range that spans all the elements in the container.

Complexity: $(BIGOH 1)
*/
            HeapRange opSlice() {
                return HeapRange(this,0, node_count);
            }
            ConstHeapRange opSlice() const{
                return ConstHeapRange(this,0, node_count);
            }

/**
Returns the number of elements in the container.

Complexity: $(BIGOH 1).
*/
            @property size_t length()const{
                return node_count;
            }

/**
Property returning $(D true) if and only if the container has no
elements.

Complexity: $(BIGOH 1)
*/
            @property bool empty()const{
                return node_count == 0;
            }

/**
Returns: the max element in this index
Complexity: $(BIGOH 1)
*/
            @property front() inout{
                return _heap[0].value;
            }
/**
Returns: the back of this index
Complexity: $(BIGOH 1)
*/
            @property back() inout{
                return _heap[node_count-1].value;
            }

            void _ClearIndex(){
                fill(_heap, (ThisNode*).init);
            }
/**
??
*/
            void clear(){
                _Clear();
            }

            void modify(SomeRange, Modifier)(SomeRange r, Modifier mod)
                if(is(SomeRange == HeapRange) ||
                   is(ElementType!SomeRange == Position!ThisNode)) {
                    while(!r.empty) {
                        static if(is(SomeRange == HeapRange)) {
                            ThisNode* node = r.front_node;
                        }else{
                            ThisNode* node = r.front.node;
                        }
                        r.popFront();
                        _Modify(node, mod);
                    }
            }

            bool replace(Position!ThisNode r, ValueView value)
            {
                return _Replace(r.node, cast(Value) value);
            }

            KeyType _NodePosition(ThisNode* node){
                return key(node.value);
            }

            bool _PositionFixable(ThisNode* node, KeyType oldPosition,
                    out ThisNode* cursor){
                return true;
            }

            void _FixPosition(ThisNode* node, KeyType oldPosition,
                    ThisNode* cursor){
                // sift will take O(1) if key hasn't changed
                sift(node.index!N._index);
            }

            bool _NotifyChange(ThisNode* node){
                // sift will take O(1) if key hasn't changed
                sift(node.index!N._index);
                return true;
            }

/**
Returns the _capacity of the index, which is the length of the
underlying store
*/
            size_t capacity()const{
                return _heap.length;
            }

/**
Ensures sufficient capacity to accommodate $(D n) elements.

Postcondition: $(D capacity >= n)

Complexity: $(BIGOH ??) if $(D e > capacity),
otherwise $(BIGOH 1).
*/
            void reserve(size_t count){
                if(_heap.length < count){
                    auto newheap = Allocator.allocate!(ThisNode*)(count)[0 .. count];
                    auto rest = moveAll(_heap, newheap);
                    fill(rest, (ThisNode*).init);
                    Allocator.deallocate(_heap.ptr);
                    _heap = newheap;
                }
            }
/**
Inserts value into this heap, unless another index refuses it.
Returns: the number of values added to the container
Complexity: $(BIGOH i(n)); $(BR) $(BIGOH log(n)) for this index
*/
            size_t insert(SomeValue)(SomeValue value)
            if(isImplicitlyConvertible!(SomeValue, ValueView))
            {
                ThisNode* n = _InsertAllBut!N(value);
                if(!n) return 0;
                node_count--;
                _Insert(n);
                node_count++;
                return 1;
            }

            size_t insert(SomeRange)(SomeRange r)
            if(isImplicitlyConvertible!(ElementType!SomeRange, ValueView))
            {
                size_t count;
                foreach(e; r){
                    count += insert(e);
                }
                return count;
            }

            void _Insert(ThisNode* node){
                if(node_count == _heap.length){
                    reserve(max(_heap.length*2+1, node_count+1));
                }
                _heap[node_count] = node;
                _heap[node_count].index!N._index = node_count;
                sift(node_count);
            }

/**
Removes the max element of this index from the container.
Complexity: $(BIGOH d(n)); $(BR) $(BIGOH log(n)) for this index
*/
            void removeFront(){
                _RemoveAll(_heap[0]);
            }

            void _Remove(ThisNode* node){
                if(node.index!N._index == node_count-1){
                    _heap[node_count-1] = null;
                }else{
                    size_t ix = node.index!N._index;
                    swapAt(ix, node_count-1);
                    _heap[node_count-1] = null;
                    node_count--;
                    sift(ix);
                    node_count++;
                }
            }
/**
Forwards to removeFront
*/
            alias removeFront removeAny;


/**
* removes the back of this index from the container. Why would you do this?
No idea.
Complexity: $(BIGOH d(n)); $(BR) $(BIGOH 1) for this index
*/
            void removeBack(){
                ThisNode* node = _heap[node_count-1];
                _RemoveAll(node);
            }

            HeapRange remove(R)(R r)
            if (is(R == HeapRange) ||
                is(ElementType!R == Position!ThisNode)){
                while(!r.empty){
                    static if(is(R == HeapRange)){
                        ThisNode* node = r.front_node;
                    }else{
                        ThisNode* node = r.front.node;
                        r.front.obliterated = true;
                    }
                    r.popFront();
                    _RemoveAll(node);
                }
                return HeapRange(this,0,0);
            }

            bool isLe(size_t a, size_t b){
                return(!less(key(_heap[b].value),key(_heap[a].value)));
            }

            bool _invariant(size_t i){
                bool result = true;
                if(i > 0){
                    result &= (isLe(i,p(i)));
                }
                if( l(i) < node_count ){
                    result &= (isLe(l(i), i));
                }
                if( r(i) < node_count ){
                    result &= (isLe(r(i), i));
                }
                return result;
            }

            void _NodeReplace(ThisNode* old, ThisNode* newnode) {
                move(newnode, _heap[old.index!N._index]);
                newnode.index!N._index = old.index!N._index;
            }

            void _Check(){
                for(size_t i = 0; i < node_count; i++){
                    assert (_heap[i].index!N._index == i);
                    assert (_invariant(i));
                }

            }

            void printHeap(){
                printHeap1(0,0);
            }

            void printHeap1(size_t n, size_t indent){
                if (l(n) < node_count) printHeap1(l(n), indent+1);
                for(int i = 0; i < indent; i++)
                    write("..");
                static if(__traits(compiles, (_heap[n].value.toString0()))){
                    writefln("%s (%s) %s", n, _heap[n].value.toString0(), _invariant(n) ? "" : "<--- bad!!!");
                }else{
                    writefln("(%s)", _heap[n].value);
                }

                if (r(n) < node_count) printHeap1(r(n), indent+1);
            }

            string toString0(){
                string r = "[";
                auto rng = opSlice();
                while(!rng.empty){
                    r ~= format("%s", (rng.front));
                    rng.popFront();
                    r ~= rng.empty ? "]" : ", ";
                }
                return r;
            }

            private HeapRange fromNode(ThisNode* n){
                return HeapRange(this, n.index!N._index, this.node_count);
            }
        }
    }
}

// thieved from boost::multi_index::detail::bucket_array.
static if(size_t.sizeof == 4){
    immutable size_t[] primes = [
        53u, 97u, 193u, 389u, 769u,
        1543u, 3079u, 6151u, 12289u, 24593u,
        49157u, 98317u, 196613u, 393241u, 786433u,
        1572869u, 3145739u, 6291469u, 12582917u, 25165843u,
        50331653u, 100663319u, 201326611u, 402653189u, 805306457u,
        1610612741u, 3221225473u, 4294967291u
    ];
}else static if(size_t.sizeof == 8){
    immutable size_t[] primes = [
        53uL, 97uL, 193uL, 389uL, 769uL,
        1543uL, 3079uL, 6151uL, 12289uL, 24593uL,
        49157uL, 98317uL, 196613uL, 393241uL, 786433uL,
        1572869uL, 3145739uL, 6291469uL, 12582917uL, 25165843uL,
        50331653uL, 100663319uL, 201326611uL, 402653189uL, 805306457uL,
        1610612741uL, 3221225473uL, 4294967291uL,
        6442450939uL, 12884901893uL, 25769803751uL, 51539607551uL,
        103079215111uL, 206158430209uL, 412316860441uL, 824633720831uL,
        1649267441651uL, 3298534883309uL, 6597069766657uL, 13194139533299uL,
        26388279066623uL, 52776558133303uL, 105553116266489uL,
        211106232532969uL,
        422212465066001uL, 844424930131963uL, 1688849860263953uL,
        3377699720527861uL, 6755399441055731uL, 13510798882111483uL,
        27021597764222939uL, 54043195528445957uL, 108086391056891903uL,
        216172782113783843uL, 432345564227567621uL, 864691128455135207uL,
        1729382256910270481uL, 3458764513820540933uL, 6917529027641081903uL,
        13835058055282163729uL, 18446744073709551557uL
    ];
}else static assert(false,
        Replace!("waht is this weird sizeof(size_t) == %s?", "%s",size_t.sizeof));

/// a hash table index
/// KeyFromValue(value) = key of type KeyType
/// Hash(key) = hash of type size_t
/// Eq(key1, key2) determines equality of key1, key2
template Hashed(bool allowDuplicates = false, alias KeyFromValue="a",
        alias Hash="typeid(a).getHash(&a)", alias Eq="a==b") {
    // this index allocates the table, and an array in removeKey

    enum bool BenefitsFromSignals = true;

    /// _
    template Inner(ThisContainer, ThisNode, Value, ValueView, size_t N, Allocator) {
        alias unaryFun!KeyFromValue key;
        alias typeof(key(Value.init)) KeyType;

        alias TypeTuple!(N) NodeTuple;
        alias TypeTuple!(N,KeyFromValue, Hash, Eq, allowDuplicates,
                Sequenced!().Inner!(ThisContainer, ThisNode,Value,ValueView,N,Allocator).SequencedRange,
                ThisContainer) IndexTuple;
        // node implementation
        // could be singly linked, but that would make aux removal more
        // difficult
        alias Sequenced!().Inner!(ThisContainer, ThisNode, Value, ValueView,N,Allocator).NodeMixin
            NodeMixin;

        enum IndexCtorMixin = Replace!(q{
            index!$N .hashes = Allocator.allocate!(ThisNode*)(primes[0])[0 .. primes[0]];
            index!$N .load_factor = 0.80;
        }, "$N", N);

        /// index implementation
        mixin template IndexMixin(size_t N, alias KeyFromValue, alias Hash,
                alias Eq, bool allowDuplicates, alias SeqRange, ThisContainer){
            alias unaryFun!KeyFromValue key;
            alias typeof(key((Value).init)) KeyType;
            alias unaryFun!Hash hash;
            alias binaryFun!Eq eq;
            alias SeqRange!false BucketSeqRange;
            alias SeqRange!true ConstBucketSeqRange;

            /// the primary range for this index, which embodies a forward
            /// range. iteration has time complexity O(n)
            struct HashedRangeT(bool is_const) {
                static if(is_const) {
                    alias const(ThisNode) Node;
                    alias const(ThisContainer) Container;
                }else {
                    alias ThisContainer Container;
                    alias ThisNode Node;
                }
                Container c;
                Node* node;
                alias node front_node;
                size_t n;

                this(Container _c, Node* _node, size_t _n) {
                    c = _c;
                    node = _node;
                    n = _n;
                }

                @property bool empty()/*const*/{
                    return n >= c.index!N.hashes.length;
                }

                @property front() {
                    return node.value;
                }

                void popFront(){
                    node = node.index!N.next;
                    if(!node){
                        do n++;
                        while(n < c.index!N.hashes.length && !c.index!N.hashes[n]);
                        if( n < c.index!N.hashes.length ){
                            node = c.index!N.hashes[n];
                        }
                    }
                }

                @property save(){
                    return this;
                }
            }

            alias HashedRangeT!true ConstHashedRange;
            alias HashedRangeT!false HashedRange;

            template IsMyRange(T) {
                enum bool IsMyRange =
                    is(T == HashedRange) ||
                    is(T == ConstHashedRange) ||
                    is(T == BucketSeqRange) ||
                    is(T == ConstBucketSeqRange);
            }

            ThisNode*[] hashes;
            ThisNode* _first;
            double load_factor;

            bool isFirst(ThisNode* n){
                version(BucketHackery){
                    size_t ix = cast(size_t) n.index!N.prev;
                    return ix < hashes.length && hashes[ix] == n;
                }else{
                    return n.index!N.prev is null;
                }
            }

            // sets n as the first in bucket list at index
            void setFirst(ThisNode* n, size_t index){
                // first: see if the index of this bucket list is before
                // _front's bucket list index
                version(BucketHackery){
                    size_t findex = !_first?-1:
                        cast(size_t) _first.index!N.prev;
                }else{
                    size_t findex = !_first?-1:
                        hash(key(_first.value))%hashes.length;
                }
                if(findex >= index) _first = n;
                if(hashes[index] && hashes[index] != n){
                    version(BucketHackery){
                        // be sure not to give insertPrev any bogus
                        // links to follow and impale itself with
                        hashes[index].index!N.prev=null;
                    }
                    hashes[index].index!N.insertPrev(n);
                }
                hashes[index] = n;
                version(BucketHackery){
                    n.index!N.prev = cast(ThisNode*) index;
                }
            }

            void removeFirst(ThisNode* n){
                version(BucketHackery){
                    size_t index = cast(size_t) n.index!N.prev;
                }else{
                    size_t index = hash(key(n.value))%hashes.length;
                }
                auto nxt = n.index!N.next;
                hashes[index] = nxt;
                n.index!N.next = null;
                n.index!N.prev = null;
                if (nxt){
                    version(BucketHackery){
                        nxt.index!N.prev = cast(ThisNode*) index;
                    }else{
                        nxt.index!N.removePrev();
                    }
                    if(_first == n){
                        _first = nxt;
                    }
                }else if(_first == n){
                    while(index < hashes.length && !hashes[index]){
                        index++;
                    }
                    if(index < hashes.length) _first = hashes[index];
                }
            }


/**
Returns the number of elements in the container.

Complexity: $(BIGOH 1).
*/
            @property size_t length()const{
                return node_count;
            }

/**
Property returning $(D true) if and only if the container has no
elements.

Complexity: $(BIGOH 1)
*/
            @property bool empty()const{
                return node_count == 0;
            }

/**
Preconditions: !empty
Complexity: $(BIGOH 1)
*/
            @property front() inout{
                return _first.value;
            }

            void _ClearIndex(){
                _first = null;
                fill(hashes, cast(ThisNode*)null);
            }
/**
??
*/
            void clear(){
                _Clear();
            }

/**
Gets a range of all elements in container.
Complexity: $(BIGOH 1)
*/
            HashedRange opSlice(){
                if(empty) return HashedRange(this, null, hashes.length);
                auto ix = hash(key(_first.value))%hashes.length;
                return HashedRange(this, _first, ix);
            }
            ConstHashedRange opSlice() const{
                if(empty)
                    return ConstHashedRange(this, null, hashes.length);
                auto ix = hash(key(_first.value))%hashes.length;
                return ConstHashedRange(this, _first, ix);
            }

            // returns true iff k was found.
            // when k in hashtable:
            // node = first node in hashes[ix] such that eq(key(node.value),k)
            // when k not in hashtable:
            // node = null -> put value of k in hashes[ix]
            // or node is last node in hashes[ix] chain ->
            //  put value of k in node.next
            bool _find(const(KeyType) k, out inout(ThisNode)* node, out size_t index) inout{
                index = hash(k)%hashes.length;
                if(!hashes[index]){
                    node = null;
                    return false;
                }
                node = hashes[index];
                // TODO: figure out unaryFun & inout
                while(!eq(k, key(cast()node.value))){
                    if (node.index!N.next is null){
                        return false;
                    }
                    node = node.index!N.next;
                }
                return true;
            }

            static if(!allowDuplicates){
/**
Available for Unique variant.
Complexity:
$(BIGOH n) ($(BIGOH 1) on a good day)
*/
                ValueView opIndex ( KeyType k ) const{
                    const(ThisNode)* node;
                    size_t index;
                    enforce(_find(k, node, index));
                    return cast(ValueView) node.value;
                }
            }

/**
Reports whether a value exists in the collection such that eq(k, key(value)).
Complexity:
$(BIGOH n) ($(BIGOH 1) on a good day)
 */
            static if(!isImplicitlyConvertible!(KeyType, ValueView)){
                bool opBinaryRight(string op)(KeyType k) const
                if (op == "in")
                {
                    ThisNode* node;
                    size_t index;
                    return _find(k, node,index);
                }
            }

/**
Reports whether value exists in this collection.
Complexity:
$(BIGOH n) ($(BIGOH n 1) on a good day)
 */
            bool opBinaryRight(string op)(ValueView value) const
            if (op == "in")
            {
                const(ThisNode)* node;
                size_t index;
                return _find(key(value), node,index);
            }

/**
Reports whether value exists in this collection
Complexity:
$(BIGOH n) ($(BIGOH n 1) on a good day)
 */
            bool containsValue(ValueView value) const{
                const(ThisNode)* node;
                size_t index;
                auto r =  _find(key(value), node,index);
                return r;
            }

            ///ditto
            bool contains(KeyType k) const{
                const(ThisNode)* node;
                size_t index;
                return _find(k, node,index);
            }

            void modify(SomeRange, Modifier)(SomeRange r, Modifier mod)
            if(is(SomeRange == HashedRange) ||
               is(ElementType!SomeRange == Position!ThisNode)) {
                while(!r.empty) {
                    static if(is(SomeRange == HashedRange)) {
                        ThisNode* node = r.front_node;
                    }else{
                        ThisNode* node = r.front.node;
                    }
                    r.popFront();
                    _Modify(node, mod);
                }
            }

            bool replace(Position!ThisNode r, ValueView value) {
                return _Replace(r.node, cast(Value) value);
            }

            KeyType _NodePosition(ThisNode* node){
                return key(node.value);
            }

            // cursor = null -> no fixup necessary or fixup to start of chain
            // cursor != null -> fixup necessary
            bool _PositionFixable(ThisNode* node, KeyType oldPosition,
                    out ThisNode* cursor){
                cursor = null;
                auto newPosition = key(node.value);
                if(eq(newPosition, oldPosition)) return true;
                static if(allowDuplicates){
                    cursor = node;
                    return true;
                }else{
                    ThisNode* n;
                    size_t index;
                    return !(_find(newPosition, cursor, index));
                }

            }

            void _FixPosition(ThisNode* node, KeyType oldPosition,
                    ThisNode* cursor){
                auto newPosition = key(node.value);
                if(eq(newPosition, oldPosition)) return;
                static if(allowDuplicates){
                    if(cursor){
                        _Remove(node);
                        node.index!N.prev = null;
                        node.index!N.next = null;
                        _Insert(node);
                    }
                }else{
                    if(eq(oldPosition, key(node.value))) return;
                    _Remove(node);
                    _Insert(node, cursor);
                }
            }

            bool _NotifyChange(ThisNode* node){
                size_t index;
                if(isFirst(node)){
                    version(BucketHackery){
                        index = cast(size_t) node.index!N.prev;
                    }else{
                        static assert(0,"signals not implemented for Hashed " ~
                                "indices without version=BucketHackery");
                    }
                }else{
                    index = hash(key(node.index!N.prev.value))%hashes.length;
                }

                size_t newindex = hash(key(node.value))%hashes.length;
                if(index != newindex){
                    ThisNode* cursor;
                    _Remove(node);
                    if(_find(key(node.value), cursor, newindex)){
                        static if(!allowDuplicates){
                            _RemoveAllBut!N(node);
                            return false;
                        }else{
                            if(isFirst(cursor)){
                                setFirst(node, index);
                            }else{
                                cursor.index!N.insertPrev(node);
                            }
                        }
                    }else if(cursor){
                        cursor.index!N.insertNext(node);
                    }else{
                        setFirst(node, index);
                    }
                    return true;
                }
                return true;
            }


/**
Returns a range of all elements with eq(key(elem), k).
Complexity:
$(BIGOH n) ($(BIGOH n $(SUB result)) on a good day)
 */
            // TODO: compact these back into one
            BucketSeqRange equalRange( KeyType k ){
                ThisNode* node;
                size_t index;
                if(!_find(k, node,index)){
                    return BucketSeqRange(this,null,null);
                }
                static if(!allowDuplicates){
                    return BucketSeqRange(this,node,node);
                }else{
                    ThisNode* node2 = node;
                    while(node2.index!N.next !is null &&
                            eq(k, key(node2.index!N.next.value))){
                        node2 = node2.index!N.next;
                    }
                    return BucketSeqRange(this, node, node2);
                }
            }
            ConstBucketSeqRange equalRange( KeyType k ) const{
                const(ThisNode)* node;
                size_t index;
                if(!_find(k, node,index)){
                    return ConstBucketSeqRange(this,null,null);
                }
                static if(!allowDuplicates){
                    return ConstBucketSeqRange(this,node,node);
                }else{
                    const(ThisNode)* node2 = node;
                    while(node2.index!N.next !is null &&
                            eq(k, key(node2.index!N.next.value))){
                        node2 = node2.index!N.next;
                    }
                    return ConstBucketSeqRange(this, node, node2);
                }
            }

            static if(allowDuplicates){
                void _Insert(ThisNode* n){
                    ThisNode* cursor;
                    size_t index;
                    if(_find(key(n.value), cursor, index)){
                        if(isFirst(cursor)){
                            setFirst(n, index);
                        }else{
                            cursor.index!N.insertPrev(n);
                        }
                    }else if(cursor){
                        cursor.index!N.insertNext(n);
                    }else{
                        setFirst(n, index);
                    }
                }
            }else{
                bool _DenyInsertion(ThisNode* node, out ThisNode* cursor)
                {
                    size_t index;
                    auto r =  _find(key(node.value), cursor, index);
                    return r;
                }
                void _Insert(ThisNode* node, ThisNode* cursor){
                    if(cursor){
                        cursor.index!N.insertNext(node);
                    }else{
                        size_t index = hash(key(node.value))%hashes.length;
                        assert ( !hashes[index] );
                        setFirst(node, index);
                    }
                }
            }

            void _Remove(ThisNode* n){
                if(isFirst(n)){
                    removeFirst(n);
                }else{
                    n.index!N.prev.index!N.removeNext();
                }
            }

            @property loadFactor() const{
                return load_factor;
            }

            @property loadFactor(size_t _load_factor) {
                load_factor = load_factor;
                // TODO: what else do we do here?
                assert(0);
            }

            size_t maxLoad(size_t n) const{
                double load = n * load_factor;
                if(load > size_t.max) return size_t.max;
                return cast(size_t) load;
            }

            @property size_t capacity() const{
                return hashes.length;
            }

            void reserve(size_t n){
                if (n <= maxLoad(hashes.length)) return;
                size_t i = 0;
                while(i < primes.length && maxLoad(primes[i]) < n){
                    i++;
                }
                if (hashes.length == primes[i] && i == primes.length-1){
                    // tough
                    return;
                }else if (hashes.length >= primes[i]){
                    // hmm.
                    return;
                }

                auto r = opSlice();
                auto newhashes = Allocator.allocate!(ThisNode*)(primes[i])[0 .. primes[i]];
                ThisNode* newfirst;
                size_t newfindex = -1;
                while(!r.empty){
                    ThisNode* node = r.front_node;
                    ThisNode* lastInChain = node;
                    auto k = key(node.value);
                    size_t index = hash(key(node.value))%newhashes.length;
                    r.popFront();
                    while(!r.empty && eq(k, key(r.front))){
                        lastInChain = r.front_node;
                        r.popFront();
                    }
                    version(BucketHackery){
                        node.index!N.prev = cast(ThisNode*)index;
                    }else{
                        node.index!N.prev = null;
                    }
                    lastInChain.index!N.next = null;
                    if(!newhashes[index]){
                        newhashes[index] = node;
                        if (index < newfindex){
                            newfirst = node;
                            newfindex = index;
                        }
                    }else{
                        auto p = newhashes[index];
                        newhashes[index] = node;
                        p.index!N.prev = lastInChain;
                        lastInChain.index!N.next = p;
                        if(newfirst == p){
                            newfirst = node;
                        }
                    }
                }

                Allocator.deallocate(hashes.ptr);
                hashes = newhashes;
                _first = newfirst;
            }
/**
insert value into this container. For Unique variant, will refuse value
if value already exists in index.
Returns:
number of items inserted into this container.
Complexity:
$(BIGOH i(n)) $(BR) $(BIGOH n) for this index ($(BIGOH 1) on a good day)
*/
            size_t insert(SomeValue)(SomeValue value)
            if(isImplicitlyConvertible!(SomeValue, ValueView)) {
                ThisNode* node;
                size_t index;
                if(maxLoad(hashes.length) < node_count+1){
                    reserve(max(maxLoad(2* hashes.length + 1), node_count+1));
                }
                static if(!allowDuplicates){
                    // might deny, so have to look
                    auto k = key(value);
                    bool found = _find(k, node, index);
                    if(found) return 0;
                    ThisNode* newnode = _InsertAllBut!N(value);
                    if(!newnode) return 0;
                }else{
                    // won't deny, so don't bother looking until
                    // we know other indices won't deny.
                    ThisNode* newnode = _InsertAllBut!N(value);
                    if(!newnode) return 0;
                    auto k = key(value);
                    bool found = _find(k, node, index);
                }
                if(found){
                    // meh, lets not walk to the end of equal range
                    if (isFirst(node)){
                        setFirst(newnode,index);
                    }else{
                        node.index!N.insertPrev(newnode);
                    }
                }else if(node){
                    node.index!N.insertNext(newnode);
                }else{
                    setFirst(newnode,index);
                }
                return 1;
            }

/**
insert contents of r into this container. For Unique variant, will refuse
any items in content if it already exists in index.
Returns:
number of items inserted into this container.
Complexity:
$(BIGOH i(n)) $(BR) $(BIGOH n+n $(SUB r)) for this index
($(BIGOH n $(SUB r)) on a good day)
*/
            size_t insert(SomeRange)(SomeRange r)
            if(isImplicitlyConvertible!(ElementType!SomeRange, ValueView)){
                size_t count = 0;
                static if(hasLength!SomeRange){
                    if(maxLoad(node_count) < node_count+r.length){
                        reserve(max(2 * node_count + 1, node_count+r.length));
                    }
                }
                foreach(e; r){
                    count += insert(e);
                    static if(hasLength!SomeRange){
                        if(maxLoad(node_count) < node_count+1){
                            reserve(max(2* node_count + 1, node_count+1));
                        }
                    }
                }
                return count;
            }

/**
Removes all of r from this container.
Preconditions:
r came from this index
Returns:
an empty range
Complexity:
$(BIGOH n $(SUB r) * d(n)), $(BR)
$(BIGOH n $(SUB r)) for this index
*/
            HashedRange remove(R)( R r )
            if(is(R == HashedRange) || is(R == BucketSeqRange) ||
               is(ElementType!R == Position!ThisNode)){
                while(!r.empty){
                    static if(IsMyRange!R){
                        ThisNode* node = r.front_node;
                    }else{
                        ThisNode* node = r.front.node;
                        r.front.obliterated = true;
                    }
                    r.popFront();
                    _RemoveAll(node);
                }
                return HashedRange(this, null, hashes.length);
            }

/**
Removes all elements with key k from this container.
Returns:
the number of elements removed
Complexity:
$(BIGOH n $(SUB k) * d(n)), $(BR)
$(BIGOH n + n $(SUB k)) for this index ($(BIGOH n $(SUB k)) on a good day)
*/
            version(OldWay){
            size_t removeKey(KeyType k){
                auto r = equalRange(k);
                size_t count = 0;
                while(!r.empty){
                    ThisNode* node = r._front;
                    r.popFront();
                    _RemoveAll(node);
                    count++;
                }
                return count;
            }
            }else{

            size_t removeKey(Keys...)(Keys keys)
            if(allSatisfy!(implicitlyConverts,Keys)) {
                Unqual!KeyType[Keys.length] toRemove;
                foreach(i,k; keys) {
                    Unqual!KeyType k2 = k;
                    toRemove[i] = k2;
                }
                return removeKey(cast(KeyType[]) (toRemove[]));
            }

            size_t removeKey(Key)(Key[] keys)
            if(isImplicitlyConvertible!(Key, KeyType))
            out(r){
                version(RBDoChecks) _Check();
            }body{
                ThisNode* node;
                size_t index;
                size_t count = 0;

                foreach(k; keys)
                {
                    if(!_find(k, node, index)){
                        continue;
                    }
                    _RemoveAll(node);
                    count++;
                }

                return count;
            }

            private template implicitlyConverts(Key){
                enum implicitlyConverts = isImplicitlyConvertible!(Key,KeyType);
            }

            /++ Ditto +/
            size_t removeKey(Stuff)(Stuff stuff)
            if(isInputRange!Stuff &&
            isImplicitlyConvertible!(ElementType!Stuff, KeyType) &&
            !isDynamicArray!Stuff) {
                //We use array in case stuff is a Range from this
                // hash - either directly or indirectly.
                auto stuffy = allocatedArray!Allocator(stuff);
                auto res = removeKey(stuffy);
                Allocator.deallocate(stuffy.ptr);
                return res;
            }
            }

            void _NodeReplace(ThisNode* old, ThisNode* newnode) {
                  ThisNode* next = old.index!N.next;
                  ThisNode* prev = old.index!N.prev;
                  newnode.index!N.next = next;
                  newnode.index!N.prev = prev;
                  if(next) {
                      next.index!N.prev = newnode;
                  }
                  if(prev) {
                      prev.index!N.next = newnode;
                  }
                  if(old is _first) {
                      _first = newnode;
                  }

                  old.index!N.prev = null;
                  old.index!N.next = null;
            }

            void _Check(){
                bool first = true;
                foreach(i, node; hashes){
                    if(!node) continue;
                    if(first){
                        assert(_first is node);
                        first = false;
                    }
                    assert(isFirst(node));
                    ThisNode* prev = null;
                    while(node){

                        assert(hash(key(node.value))%hashes.length == i);
                        if(!isFirst(node)){
                            static if(!allowDuplicates){
                                assert(!eq(key(prev.value), key(node.value)));
                            }
                            // gonna be hard to enforce that equal elements are contiguous
                        }

                        prev = node;
                        node = node.index!N.next;
                    }
                }
            }

            string toString0(){
                string r = "[";
                auto rng = opSlice();
                while(!rng.empty){
                    r ~= format("%s", (rng.front));
                    rng.popFront();
                    r ~= rng.empty ? "]" : ", ";
                }
                return r;
            }

            private HashedRange fromNode(ThisNode* n){
                auto ix = hash(key(n.value))%this.index!N.hashes.length;
                return HashedRange(this, n, ix);
            }
        }
    }
}

/// _
template HashedUnique(alias KeyFromValue="a",
        alias Hash="typeid(a).getHash(&a)", alias Eq="a==b"){
    alias Hashed!(false, KeyFromValue, Hash, Eq) HashedUnique;
}
/// _
template HashedNonUnique(alias KeyFromValue="a",
        alias Hash="typeid(a).getHash(&a)", alias Eq="a==b"){
    alias Hashed!(true, KeyFromValue, Hash, Eq) HashedNonUnique;
}


class Position(MNode) {
    alias MNode.ThisContainer.ValueView ValueView;
    alias MNode.ThisContainer.Allocator Allocator;

    @property ValueView v() {
        return node.value;
    }

    private:
        bool obliterated = true;
        MNode* _node;

        @disable this();

        static auto create(MNode* _node) {
            import std.conv : emplace;
            auto p = cast(Position)Allocator.allocate!void(__traits(classInstanceSize, Position));
            p.emplace();
            p.obliterated = false;
            p._node = _node;
            return p;
        }

        void release(Position p){
            Allocator.deallocate(cast(void*) p);
        }

        @property node() {
            enforce(!obliterated,
                    "this position no longer exists in container");
            return _node;
        }
}

auto PSR(Range)(Range rng)
{
    alias Position!(typeof(*rng.front_node)) Pos;

    static struct PositionRange {

        Range source;

        @property empty() {
            return source.empty();
        }

        @property Pos front() {
            return Pos.create(source.front_node);
        }

        void popFront() {
            source.popFront();
        }

        static if(isBidirectionalRange!Range) {
            @property Pos back() {
                return Pos.create(source.back_node);
            }

            void popBack() {
                source.popBack();
            }
        }

        static if(isForwardRange!Range) {
            @property save() {
                return PositionRange(source.save());
            }
        }

        static if(isRandomAccessRange!Range) {
            auto opIndex(size_t i) {
                return source.nth_node(i);
            }

            @property length() {
                return source.length;
            }

            @property front(typeof(source.front_node) n) {
                source.front_node = n;
            }

            @property opSlice(size_t a, size_t b) {
                return PositionRange(source[a .. b]);
            }
        }
    }

    return PositionRange(rng);
}

struct IndexedBy(L...)
{
    template _inner(size_t index, List...) {
        static if(List.length <= 1) {
            alias TypeTuple!() names;
            alias TypeTuple!() name_indices;
            alias TypeTuple!(List) indices;
        }else static if(IsIndex!(List[0]) && is(typeof(List[1]) == string)) {
            alias _inner!(index+1,List[2 .. $]) next;
            alias TypeTuple!(List[1], next.names) names;
            alias TypeTuple!(index, next.name_indices) name_indices;
            alias TypeTuple!(List[0], next.indices) indices;
        }else {
            alias _inner!(index+1,List[1 .. $]) next;
            alias next.names names;
            alias next.name_indices name_indices;
            alias TypeTuple!(List[0], next.indices) indices;
        }
    }

    alias _inner!(0, L).names Names;
    alias _inner!(0, L).name_indices NameIndices;
    alias _inner!(0, L).indices Indices;
    alias L List;
}

template GetMixinAlias(valueSignal){
    alias valueSignal.MixinAlias GetMixinAlias;
}

// todo - find better name
template OU(T){
    template arr2tuple(stuff...){
        static assert(is(typeof(stuff[0]) == T[]));

        static if(stuff[0].length){
            alias arr2tuple!(stuff[0][1 .. $], stuff[1 .. $], stuff[0][0]) arr2tuple;
        }else{
            alias stuff[1 .. $] arr2tuple;
        }
    }

    T[] orderedUniqueInsert(T[] x, T value){
        size_t i;
        while(i < x.length && x[i] < value) i++;
        if(i < x.length && x[i] == value) return x;
        T[] ret = new T[](x.length+1);
        ret[0 .. i] = x[0 .. i];
        ret[i] = value;
        ret[i+1 .. $] = x[i .. $];
        return ret;
    }
    T[] TypeList2SortedArray(L...)(){
        alias L List;
        T[] ret = [];
        foreach(T l; List){
            ret = orderedUniqueInsert(ret, l);
        }
        return ret;
    }
}

/**
Specifies how to hook up value signals to indices.

A value type Value is a signal whenever Value supports the signal
interface, ie $(BR)

value.connect(void delegate() slot) $(BR)
value.disconnect(void delegate() slot)

and has the semantics that whenever value changes in a way that will cause
its position in index to change or become invalid, a call is made to slot.
The index will respond by fixing the position, or if that is not possible,
by throwing an exception.

A value may contain multiple signals within different mixin aliases. If this
is the case, the interface is

value.mixinAlias.connect(void delegate() slot) $(BR)
value.mixinAlias.disconnect(void delegate() slot)

where mixinAlias is passed in as a string to each element of L.

Arguments must be instantiations of ValueSignal.

Signals to single indices can be specified by ValueSignal!(index[, mixinAlias])

Signals to all indices can be specified by ValueSignal!("*"[, mixinAlias])

A signal can be shared by multiple indices; however do not associate a signal
to the same index more than once.
*/

struct ValueChangedSlots(L...) {
    struct Inner(IndexedBy){
        // by some forward referencing error or other, (issue 6475)
        // I can't seem to get a hold of inner in, but
        // typeof(exposeType()) seems to work. Desparate times require
        // desparate measures, I guess
        static exposeType(){
            Inner i;
            return i;
        }
        enum N = IndexedBy.Indices.length;
        alias ExpandStarSignals!(IndexedBy,L) List;


        template GetIndex(valueSignal){
            static if(__traits(compiles,valueSignal.Index)){
                enum GetIndex = valueSignal.Index;
            }else{
                static assert(__traits(compiles,valueSignal.Tag));
                static if(valueSignal.Tag == "*") {
                    static assert(false, "you bad, bad person");
                }else {
                    enum _TagIndex = staticIndexOf!(valueSignal.Tag, IndexedBy.Names);
                    enum GetIndex = IndexedBy.NameIndices[_TagIndex];
                }
            }
        }

        enum string[] AllSignals = OU!(string).TypeList2SortedArray!(
                NoDuplicates!(staticMap!(GetMixinAlias, List)))();

        template FindIndices(string mixinAlias, size_t i, indices...)
        if(indices.length == 1 && is(typeof(indices[0]) == size_t[])){
            static if(i < List.length){
                static if(List[i].MixinAlias == mixinAlias){
                    enum index = GetIndex!(List[i]);
                    static if(IndexedBy.Indices[index].BenefitsFromSignals){
                        enum size_t[] result =
                            FindIndices!(mixinAlias, i+1,
                                    OU!(size_t).orderedUniqueInsert(
                                        indices[0], index)).result;
                    }else{
                        enum size_t[] result =
                            FindIndices!(mixinAlias, i+1, indices[0]).result;
                    }
                }else{
                    enum size_t[] result =
                        FindIndices!(mixinAlias, i+1, indices[0]).result;
                }
            }else{
                enum size_t[] result = indices[0];
            }
        }

        template GenSets(size_t i, MI...){
            static if (i < AllSignals.length){
                enum mixinAlias = AllSignals[i];
                enum indices = FindIndices!(mixinAlias,0,cast(size_t[])[]).result;
                template InsertIndices(size_t j){
                    static if(j < MI.length){
                        static if(MI[j].Indices == indices){
                            alias TypeTuple!(MI[0 .. j],
                                    Mixin2Indices!(
                                        OU!(string).orderedUniqueInsert(
                                            MI[j].MixinAliases,mixinAlias),
                                        indices
                                        ),
                                    MI[j+1 .. $]) InsertIndices;
                        }else{
                            alias InsertIndices!(i+1) InsertIndices;
                        }
                    }else{
                        alias TypeTuple!(MI, Mixin2Indices!([mixinAlias],
                                    indices)) InsertIndices;
                    }
                }

                static if(indices.length > 0){
                    alias InsertIndices!(0) MI2;
                    alias GenSets!(i+1, MI2).result result;
                }else{
                    alias GenSets!(i+1, MI).result result;
                }
            }else{
                alias MI result;
            }
        }

        // map { set of mixin aliases -> set of indices }
        // since we don't have maps or sets in ct (boo),
        // really this is a list of ((list of mixin aliases), (list of indices))
        // with each inner list sorted ascending.
        //
        // what's the background?
        // we want to generate no more than M slots for this index/signal
        // spec, where M is the number of distinct signals (mixin aliases)
        // passed in. This should minimize the amount of additional memory
        // that each value has to keep track of.
        //
        // We also want to know when different signals share the same index
        // set, so we don't have to generate redundant slots.
        // so we generate this mapping, which should help.
        //
        // Requires: In the map's key set - a set of sets of mixin aliases -
        //  each mixin appears in exactly one set. (it is a true set)
        //  The map's value set - a set of sets of indices - is a true set,
        //  each index set is unique
        //
        // Then: for each entry in the map (K,V), we generate a slot function W
        //  inside our node. W gets connected/disconnected to/from each of
        //  the signals in K. W notifies each of the indices in V.

        alias GenSets!(0).result Mixin2Index;


        template _GetIndicesForSignal(string signal, size_t i){
            static if(i < N){
                static if(staticIndexOf!(signal, GetMixinAliases!(List[i]))
                        != -1){
                    alias TypeTuple!(i,_GetIndicesForSignal!(signal,i+1))
                        _GetIndicesForSignal;
                }else{
                    alias _GetIndicesForSignal!(signal,i+1)
                        _GetIndicesForSignal;
                }
            }else{
                alias TypeTuple!() _GetIndicesForSignal;
            }
        }

        template GetIndicesForSignal(string signal){
            alias _GetIndicesForSignal!(signal, 0) GetIndicesForSignal;
        }
    }
}

template ExpandStarSignals(IndexedBy, L...) {
    static if(L.length == 0) {
        alias TypeTuple!() ExpandStarSignals;
    }else static if(__traits(compiles,L[0].Tag) && L[0].Tag == "*") {
        alias TypeTuple!(ExpandStarSignal!(IndexedBy, 0, L[0]),
            ExpandStarSignals!(IndexedBy, L[1 .. $])) ExpandStarSignals;
    }else{
        alias TypeTuple!(L[0], ExpandStarSignals!(IndexedBy, L[1 .. $]))
            ExpandStarSignals;
    }
}

template ExpandStarSignal(IndexedBy, size_t i, ProtoSignal) {
    static if(i >= IndexedBy.Indices.length) {
        alias TypeTuple!() ExpandStarSignal;
    }else {
        alias TypeTuple!(ValueSignal!(i, ProtoSignal.MixinAlias),
            ExpandStarSignal!(IndexedBy, i+1, ProtoSignal)) ExpandStarSignal;
    }

}

/// _
struct ValueSignal(size_t index, string mixinAlias = "")
{
    enum size_t Index = index;
    enum MixinAlias = mixinAlias;
}

/// _
struct ValueSignal(string tag, string mixinAlias = "")
{
    enum Tag = tag;
    enum MixinAlias = mixinAlias;
}

struct Mixin2Indices(stuff...)
// wish we could pass arrays directly (cough)
if(stuff.length == 2 && is(typeof(stuff[0]) == string[]) &&
        is(typeof(stuff[1]) == size_t[])){
    enum string[] MixinAliases = stuff[0];
    enum size_t[] Indices = stuff[1];
}


/++
A multi_index node. Holds the value of a single element,
plus per-node headers of each index, if any.
The headers are all mixed in in the same scope. To prevent
naming conflicts, a header field must be accessed with the number
of its index.
Example:
----
alias MNode!(IndexedBy!(Sequenced!(), Sequenced!(), OrderedUnique!()), int) Node;
Node* n1 = new Node();
Node* n2 = new Node();
n1.index!0 .next = n2;
n2.index!0 .prev = n1;
n1.index!1 .prev = n2;
n2.index!1 .next = n1;
n1.index!2 .left = n2;
----
+/
struct MNode(_ThisContainer, IndexedBy, Allocator, Signals, Value, ValueView) {
    alias _ThisContainer ThisContainer;
    static if(MutableValue!(MNode, Value)) {
        Value value;
    }else{
        // do a dumb tail const sort of thing
        struct Capsule {
            Value value;
        }
        Capsule* val_ptr;

        @property Value value() pure inout { return val_ptr.value; }
        @property void value(Value v) {
            if(val_ptr != null) {
                Allocator.deallocate(val_ptr);
            }
            val_ptr = Allocator.allocate!(Capsule)(1);
            Capsule c = Capsule(v);
            move(c, *val_ptr);
        }
        this(Value val) {
            this.value = val;
        }
        ~this() {
            if(val_ptr != null) {
                Allocator.deallocate(val_ptr);
                val_ptr = null;
            }
        }
    }

    static if(Signals.AllSignals.length > 0) {
        // notifications need to go somewhere
        ThisContainer container;

        /// generate slots
        template ForEachSignal(size_t i) {
            static if(i < Signals.Mixin2Index.length) {
                alias Signals.Mixin2Index[i] Mixin2Index;

                template ForEachIndex2(size_t j) {
                    static if(j < Mixin2Index.Indices.length) {
                        enum result = Replace!(q{
                            if(!container.index!($i)._NotifyChange(&this)) {
                                goto denied;
                            }
                        }, "$i", Mixin2Index.Indices[j]) ~ ForEachIndex2!(j+1).result;
                    }else{
                        enum result = "";
                    }
                }
                enum stuff = Replace!(q{
                    void slot$i(){
                        $x
                        return;
                        denied: enforce(false, "todo: put a useful message in here");
                    }
                }, "$i", i, "$x", ForEachIndex2!(0).result);
            }else{
                enum stuff = "";
            }
        }

        enum signal_stuff = ForEachSignal!(0).stuff;
        mixin(signal_stuff);
    }


    template ForEachIndex(size_t N,L...){
        static if(L.length > 0){
            enum indexN = Replace!("index%s","%s", N);
            //alias L[0] L0;
            enum result =
                Replace!(q{
                    alias IndexedBy.Indices[$N] L$N;
                    alias L$N.Inner!(ThisContainer, typeof(this),Value,ValueView,$N, Allocator) M$N;
                    mixin M$N.NodeMixin!(M$N.NodeTuple) index$N;
                    template index(size_t n) if(n == $N){ alias index$N index; }
                },  "$N", N) ~
                ForEachIndex!(N+1, L[1 .. $]).result;
        }else{
            enum result = "";
        }
    }

    enum stuff = ForEachIndex!(0, IndexedBy.Indices).result;
    mixin(stuff);
}

struct ConstView{}
struct MutableView{}

template IsIndexedBy(alias x) {
    // test x.stringof in case we have a bare Sequenced!() or somesuch
    enum bool IsIndexedBy = __traits(compiles, x.stringof) &&
        x.stringof.startsWith("IndexedBy!") &&
        __traits(compiles, x.List);
}

template IsIndex(alias x) {
    enum bool IsIndex = __traits(hasMember, x, "Inner");
}

int IndexedByCount(X...)() {
    int r = 0;
    foreach(i,x; X){
        static if(__traits(compiles,IsIndexedBy!x) && IsIndexedBy!x) {
            r++;
        }
    }
    return r;
}
size_t[] IndexedByAllIndices(X)() {
    // erm. returns list of nonindices in IndexedBy
    size_t[] res = [];
    foreach(i,x; X.List){
        static if(!IsIndex!x &&
                (i == 0 || !IsIndex!(X.List[i-1]) || !is(typeof(x) == string))) {
            res ~= i;
        }
    }
    return res;
}


template FindIndexedBy(Args...) {
    static if(IsIndexedBy!(Args[0])) {
        alias Args[0] FindIndexedBy;
    }else {
        alias FindIndexedBy!(Args[1 .. $]) FindIndexedBy;
    }
}

template IsValueChangedSlots(alias X) {
    enum bool IsValueChangedSlots = __traits(compiles, X.stringof) &&
        X.stringof.startsWith("ValueChangedSlots!");
}

int ValueChangedSlotsCount(Args...)() {
    int r = 0;
    foreach(i,x; Args){
        static if(__traits(compiles,IsValueChangedSlots!x) && IsValueChangedSlots!x) {
            r++;
        }
    }
    return r;
}

template FindValueChangedSlots(Args...) {
    static if(Args.length == 0) {
        alias ValueChangedSlots!() FindValueChangedSlots;
    }else static if(IsValueChangedSlots!(Args[0])) {
        alias Args[0] FindValueChangedSlots;
    }else {
        alias FindValueChangedSlots!(Args[1 .. $]) FindValueChangedSlots;
    }
}

template IsConstnessView(alias T) {
    enum bool IsConstnessView = is(T == MutableView) || is(T == ConstView);
}

int ConstnessViewCount(Args...)() {
    int r = 0;
    foreach(i,x; Args){
        static if(__traits(compiles,IsConstnessView!x) && IsConstnessView!x) {
            r++;
        }
    }
    return r;
}

template FindConstnessView(Args...) {
    static if(Args.length == 0) {
        alias ConstView FindConstnessView;
    }else static if(IsConstnessView!(Args[0])) {
        alias Args[0] FindConstnessView;
    }else {
        alias FindConstnessView!(Args[1 .. $]) FindConstnessView;
    }
}

int AllocatorCount(Args...)() {
    int r = 0;
    foreach(i,x; Args){
        static if(__traits(compiles, IsAllocator!x) && IsAllocator!x) {
            r++;
        }
    }
    return r;
}

template FindAllocator(Args...) {
    static if(Args.length == 0) {
        alias GCAllocator FindAllocator;
    }else static if(IsAllocator!(Args[0])) {
        alias Args[0] FindAllocator;
    }else {
        alias FindAllocator!(Args[1 .. $]) FindAllocator;
    }
}

size_t[] IndexGarbage(Args...)() {
    size_t[] res = [];
    foreach(i,x; Args){
        static if(!(__traits(compiles,IsIndexedBy!x) && IsIndexedBy!x) &&
                !(__traits(compiles,IsValueChangedSlots!x) && IsValueChangedSlots!x) &&
                !(__traits(compiles,IsConstnessView!x) && IsConstnessView!x) &&
                !(__traits(compiles,IsAllocator!x) && IsAllocator!x)) {
            res ~= i;
        }
    }
    return res;
}


struct ComparisonEx(alias _key, alias _less) {
    alias _less _less_;
    alias binaryFun!_less less;
    alias unaryFun!_key key;
}

struct DefaultComparison(alias _less) {
    alias _less less;
}

template MultiCompare(F...) {
    template NormComps(size_t i = 0, alias Dflt = "a<b") {
        static if(i == F.length) {
            alias TypeTuple!() NormComps;
        }else {
            static if(F[i].stringof.startsWith("DefaultComparison!") &&
                    __traits(compiles, F[i].less)) {
                alias NormComps!(i+1, F[i].less) NormComps;
            }else{
                static if (F[i].stringof.startsWith("ComparisonEx!") &&
                        __traits(compiles, F[i].less) &&
                        __traits(compiles, F[i].key)) {
                    alias F[i] Cmp;
                }else {
                    alias ComparisonEx!(F[i], Dflt) Cmp;
                }
                alias TypeTuple!(Cmp, NormComps!(i+1, Dflt)) NormComps;
            }
        }
    }

    alias NormComps!() Comps;

    bool MultiCompare(T)(T a, T b) {
        foreach(i, cmp; Comps) {
            auto a1 = cmp.key(a);
            auto b1 = cmp.key(b);
            auto less = cmp.less(a1,b1);
            if(less) return true;
            auto gtr = cmp.less(b1,a1);
            if(gtr) return false;
            static if(i == Comps.length-1) {
                return false;
            }
        }
        assert(0);
    }
}

template IsCompatibleLess(Less, Key, CKey) {
    enum bool IsCompatibleLess = is(typeof({
                Less less;
                auto c = CKey.init;
                auto k = Key.init;
                less.cc_less(c,c);
                less.kc_less(k,c);
                less.ck_less(c,k);
                }));
}

struct CriterionFromKey(MultiIndex, size_t index,
        alias CompatibleKeyFromKey,
        alias CompatibleLess = "a<b") {
    alias binaryFun!CompatibleLess less;
    alias MultiIndex.index!(index).key key;
    alias MultiIndex.index!(index).KeyType KeyType;
    alias unaryFun!CompatibleKeyFromKey ckey;
    alias typeof(ckey(MultiIndex.ValueView.init)) CompatibleKeyType;

    static:
        bool kc_less(KeyType a, CompatibleKeyType b) {
            return less(ckey(a),b);
        }
        bool ck_less(CompatibleKeyType a, KeyType b) {
            return less(a, ckey(b));
        }
        bool cc_less(CompatibleKeyType a, CompatibleKeyType b) {
            return less(a, b);
        }
}

// error sinks

class MultiIndexContainer(Value, Args...)
if(IndexedByCount!(Args)() != 1) {
    static assert (IndexedByCount!(Args)() > 0, "MultiIndexContainer requires indices to be wrapped with IndexedBy!(..)");
    static assert (IndexedByCount!(Args)() < 2, "MultiIndexContainer takes exactly one IndexedBy!(..)");
}

class MultiIndexContainer(Value, Args...)
if(FindIndexedBy!Args .List.length == 0) {
    static assert(false, "MultiIndexContainer requires at least one index");
}

class MultiIndexContainer(Value, Args...)
if(IndexedByAllIndices!(FindIndexedBy!Args)().length != 0) {
    import std.conv;
    alias FindIndexedBy!Args IndexedBy;
    enum lst = IndexedByAllIndices!(IndexedBy)();
    pragma(msg, "IndexedBy contains non-index at indices");
    mixin template Frch(size_t i) {
        static if(i < lst.length) {
            static if(__traits(compiles, IndexedBy.List[lst[i]].stringof)) {
                pragma(msg, to!string(lst[i]) ~ ": " ~ IndexedBy.List[lst[i]].stringof);
            }else{
                pragma(msg, to!string(lst[i]));
            }
            mixin Frch!(i+1);
        }
    }
    mixin Frch!(0);
    static assert(false);
    // @@@ PHOBOS ISSUE 8320 @@@
    /+
    static assert (false,
            Replace!(/*"IndexedBy contains non-index at indices*/" %s", "%s",
                IndexedByAllIndices!(FindIndexedBy!Args)()));
+/
}

class MultiIndexContainer(Value, Args...)
if(ValueChangedSlotsCount!(Args)() > 1) {
    static assert(false, "Multiple ValueChangedSlots specifications are not allowed");
}

class MultiIndexContainer(Value, Args...)
if(ConstnessViewCount!(Args)() > 1) {
    static assert(false, "Multiple Constness Views are not allowed");
}

class MultiIndexContainer(Value, Args...)
if(AllocatorCount!(Args)() > 1) {
    static assert(false, "Multiple allocators are not allowed");
}

class MultiIndexContainer(Value, Args...)
if(IndexGarbage!(Args)().length != 0) {
    import std.conv;
    enum lst = IndexGarbage!(Args)();
    pragma(msg, "MultiIndexContainer unknown arguments at");
    mixin template Frch(size_t i) {
        static if(i < lst.length) {
            static if(__traits(compiles, Args[lst[i]].stringof)) {
                pragma(msg, to!string(lst[i]) ~ ": " ~ Args[lst[i]].stringof);
            }else{
                pragma(msg, to!string(lst[i]));
            }
            mixin Frch!(i+1);
        }
    }
    mixin Frch!(0);
    static assert(false);
    // @@@ PHOBOS ISSUE 8320 @@@
    /+
    static assert (false,
            Replace!(/*"IndexedBy contains non-index at indices*/" %s", "%s",
                IndexedByAllIndices!(FindIndexedBy!Args)()));
+/
}

template MutableValue(Node, Value) {
    enum MutableValue = __traits(compiles, { Value value; value = Value.init; });
}

template _AllUnique(Thing...) {
    enum _AllUnique = NoDuplicates!Thing .length == Thing.length;
}
class MultiIndexContainer(Value, Args...)
if(!_AllUnique!(FindIndexedBy!Args .Names)) {
    static assert(false, "duplicates!");
}



// end error sinks

/++
The container. Don't call any index methods from this container directly; use
a reference to an individual index, which can be obtained via
---
container.get_index!N
---
or
---
container.name
---
for named indices.

If you have a range into an index of this container, you can convert it to a
range of index N via
---
container.to_range!N(range)
---
This is equivalent to c++ multi_index' project
+/
class MultiIndexContainer(Value, Args...)
if(IndexedByCount!(Args)() == 1 &&
   FindIndexedBy!Args .List.length != 0 &&
   IndexedByAllIndices!(FindIndexedBy!Args)().length == 0 &&
   _AllUnique!(FindIndexedBy!Args .Names) &&
   ValueChangedSlotsCount!(Args)() <= 1 &&
   ConstnessViewCount!(Args)() <= 1 &&
   AllocatorCount!(Args)() <= 1 &&
   IndexGarbage!(Args)().length == 0) {

    alias FindIndexedBy!Args IndexedBy;
    // @@@ DMD ISSUE 6475 @@@ following gives forward reference error
    //alias FindValueChangedSlots!Args .Inner!(IndexedBy) NormSignals;
    alias typeof(FindValueChangedSlots!Args .Inner!(IndexedBy).exposeType()) NormSignals;
    alias FindConstnessView!Args ConstnessView;
    alias FindAllocator!Args Allocator;

    static if(is(ConstnessView == ConstView)){
        alias const(Value) ValueView;
    }else static if(is(ConstnessView == MutableView)){
        alias Value ValueView;
    }else static assert(false);
    alias MNode!(typeof(this), IndexedBy,Allocator,NormSignals,Value, ValueView) ThisNode;

    /+
    template IndexedByList0(size_t i, stuff...){
        static if(i < IndexedBy.Indices.length){
            alias typeof(IndexedBy.Indices[i].Inner!(typeof(this), ThisNode, Value, i).exposeType()) x;
            alias IndexedByList0!(i+1, stuff, x).result result;
        }else{
            alias stuff result;
        }
    }

    alias IndexedByList0!(0).result IndexedByList;
    +/

    size_t node_count;

    template ForEachCtorMixin(size_t i){
        static if(i < IndexedBy.Indices.length){
            static if(is(typeof(IndexedBy.Indices[i].Inner!(typeof(this),
                                ThisNode,Value,ValueView,i,Allocator).IndexCtorMixin))){
                enum result =  IndexedBy.Indices[i].Inner!(typeof(this),
                        ThisNode,Value, ValueView,i,Allocator).IndexCtorMixin ~
                    ForEachCtorMixin!(i+1).result;
            }else enum result = ForEachCtorMixin!(i+1).result;
        }else enum result = "";
    }

    // private to help avoid people accidentally using `new`,
    // can't be @disable because then emplace doesn't work
    // no point calling initialize because emplace doesn't call this
    private this(){
    }

    void initialize(){
        mixin(ForEachCtorMixin!(0).result);
    }

    void dealloc(ThisNode* node){
        // disconnect signals from slots
        foreach(i, x; NormSignals.Mixin2Index){
            foreach(j, malias; OU!(string).arr2tuple!(x.MixinAliases)){
                static if(malias == ""){
                    mixin(Replace!(q{
                        node.value.disconnect(&node.slot$i);
                    }, "$i", i));
                }else{
                    mixin(Replace!(q{
                        node.value.$alias.disconnect(&node.slot$i);
                    }, "$i", i,"$alias", malias));
                }
            }
        }
        object.destroy(node);
        Allocator.deallocate(node);
    }

    static auto create(){
        import std.conv : emplace;
        auto c = cast(MultiIndexContainer) Allocator.allocate!void(__traits(classInstanceSize, MultiIndexContainer));
        c.emplace();
        c.initialize();
        return c;
    }

    void release(MultiIndexContainer c){
        Allocator.deallocate(cast(void*) c);
    }

    template ForEachIndex(size_t N,L...){
        static if(L.length > 0){
            enum result =
                Replace!(q{
                    alias IndexedBy.Indices[$N] L$N;
                    alias L$N.Inner!(typeof(this),ThisNode,Value, ValueView,$N,Allocator) M$N;
                    mixin M$N.IndexMixin!(M$N.IndexTuple) index$N;
                    template index(size_t n) if(n == $N){ alias index$N index; }
                    struct Index$N{
                        MultiIndexContainer _this;

                        // grr opdispatch not handle this one
                        auto opSlice(T...)(T ts){
                            return _this.index!($N).opSlice(ts);
                        }

                        // grr opdispatch not handle this one
                        auto opIndex(T...)(T ts){
                            return _this.index!($N).opIndex(ts);
                        }

                        // grr opdispatch not handle this one
                        auto opIndexAssign(T...)(T ts){
                            return _this.index!($N).opIndexAssign(ts);
                        }

                        // grr opdispatch not handle this one
                        auto opBinaryRight(string op, T...)(T ts){
                            return _this.index!($N).opBinaryRight!(op)(ts);
                        }

                        // grr opdispatch not handle this one
                        auto bounds(string bs = "[]", T)(T t1, T t2){
                            return _this.index!($N).bounds!(bs,T)(t1,t2);
                        }
                        // grr opdispatch not handle this one
                        auto bounds(V, string bs = "[]", T)(T t1, T t2){
                            return _this.index!($N).cbounds!(V,bs,T)(t1,t2);
                        }
                        // grr opdispatch not handle this one
                        auto cEqualRange(L, K)(K k)
                        {
                            return _this.index!($N).cEqualRange!(L, K).equalRange(k);
                        }
                        // grr opdispatch not handle this one
                        auto cEqualRange(L, K)(K k) const
                        {
                            return _this.index!($N).cEqualRange!(L, K).equalRange(k);
                        }

                        auto opDispatch(string s, T...)(T args){
                            mixin("return _this.index!($N)."~s~"(args);");
                        }
                    }
                    @property Index$N get_index(size_t n)() if(n == $N){
                        return Index$N(this);
                    }
                },  "$N", N) ~
                ForEachIndex!(N+1, L[1 .. $]).result;
        }else{
            enum result = "";
        }
    }

    enum stuff = (ForEachIndex!(0, IndexedBy.Indices).result);
    mixin(stuff);

    template ForEachNamedIndex(size_t i){
        static if(i >= IndexedBy.Names.length) {
            enum result = "";
        }else {
            enum result = Replace!(q{
                alias get_index!$N $name;
            }, "$N", IndexedBy.NameIndices[i], "$name", IndexedBy.Names[i]) ~
            ForEachNamedIndex!(i+1).result;
        }
    }

    enum named_stuff = ForEachNamedIndex!0 .result;
    mixin(named_stuff);


    template ForEachCheckInsert(size_t i, size_t N){
        static if(i < IndexedBy.Indices.length){
            static if(i != N && __traits(hasMember, index!i,"_DenyInsertion")){
                enum result = (Replace!(q{
                        ThisNode* aY;
                        bool bY = index!(Y)._DenyInsertion(node,aY);
                        if (bY) goto denied;
                }, "Y", i)) ~ ForEachCheckInsert!(i+1, N).result;
            }else enum result = ForEachCheckInsert!(i+1, N).result;
        }else enum result = "";
    }

    template ForEachDoInsert(size_t i, size_t N){
        static if(i < IndexedBy.Indices.length){
            static if(i != N){
                import std.traits;
                static if(ParameterTypeTuple!(index!i._Insert).length == 2){
                    enum result = Replace!(q{
                        index!(Y)._Insert(node,aY);
                    }, "Y", i) ~ ForEachDoInsert!(i+1,N).result;
                }else{
                    enum result = Replace!(q{
                        index!(Y)._Insert(node);
                    }, "Y", i) ~ ForEachDoInsert!(i+1,N).result;
                }
            }else enum result = ForEachDoInsert!(i+1, N).result;
        }else enum result = "";
    }

    ThisNode* _InsertAllBut(size_t N)(Value value){
        ThisNode* node = Allocator.allocate!(ThisNode)(1);
        static if(MutableValue!(ThisNode, Value)) {
            node.value = value;
        }else{
            auto t = ThisNode(value);
            move(t, *node);
        }

        // connect signals to slots
        foreach(i, x; NormSignals.Mixin2Index){
            static if(i == 0) node.container = this;

            foreach(j, malias; OU!(string).arr2tuple!(x.MixinAliases)){
                static if(malias == ""){
                    mixin(Replace!(q{
                        node.value.connect(&node.slot$i);
                    }, "$i", i));
                }else{
                    mixin(Replace!(q{
                        node.value.$alias.connect(&node.slot$i);
                    }, "$i", i,"$alias", malias));
                }
            }
        }

        // check with each index about insert op
        /+
        foreach(i, x; IndexedByList){
            /+
            static if(i != N && is(typeof({ ThisNode* p;
                            index!i._DenyInsertion(p,p);}))){
                enum result = (Replace!(q{
                        ThisNode* aY;
                        bool bY = index!(Y)._DenyInsertion(node,aY);
                        if (bY) goto denied;
                }, "Y", i)) ~ ForEachCheckInsert!(i+1, N).result;
            }kelse enum result = ForEachCheckInsert!(i+1, N).result;
            +/
        }
        +/
        mixin(ForEachCheckInsert!(0, N).result);
        // perform insert op on each index
        mixin(ForEachDoInsert!(0, N).result);
        node_count++;
        return node;
denied:
        return null;
    }

    template ForEachDoRemove(size_t i, size_t N){
        static if(i < IndexedBy.Indices.length){
            static if(i != N){
                enum result = Replace!(q{
                    index!(Y)._Remove(node);
                }, "Y", i) ~ ForEachDoRemove!(i+1,N).result;
            }else enum result = ForEachDoRemove!(i+1, N).result;
        }else enum result = "";
    }

    // disattach node from all indices except index N
    void _RemoveAllBut(size_t N)(ThisNode* node){
        mixin(ForEachDoRemove!(0, N).result);
        node_count --;
    }

    // disattach node from all indices.
    // @@@BUG@@@ cannot pass length directly to _RemoveAllBut
    auto _RemoveAll(size_t N = size_t.max)(ThisNode* node){
        static if(N == size_t.max) {
            enum _grr_bugs = IndexedBy.Indices.length;
            _RemoveAllBut!(_grr_bugs)(node);
        }else {
            _RemoveAllBut!N(node);
            auto res = index!N._Remove(node);
        }
        dealloc(node);

        static if(N != size_t.max) {
            return res;
        }
    }

    template ForEachIndexPosition(size_t i){
        static if(i < IndexedBy.Indices.length){
            static if(is(typeof(index!i ._NodePosition((ThisNode*).init)))){
                enum variableDeclarations = Replace!(q{
                    ThisNode* node$i;
                }, "$i", i) ~ ForEachIndexPosition!(i+1).variableDeclarations;
                enum getNodePositions = Replace!(q{
                    auto pos$i = index!$i ._NodePosition(node);
                }, "$i", i) ~ ForEachIndexPosition!(i+1).getNodePositions;
                enum gotoDeniedOnInvalid = Replace!(q{
                    if(!index!$i ._PositionFixable(node, pos$i, node$i))
                        goto denied;
                }, "$i", i) ~ ForEachIndexPosition!(i+1).gotoDeniedOnInvalid;
                enum fixupIndices = Replace!(q{
                    index!$i ._FixPosition(node, pos$i, node$i);
                }, "$i", i) ~ ForEachIndexPosition!(i+1).fixupIndices;
            }else{
                enum getNodePositions = ForEachIndexPosition!(i+1).getNodePositions;
                enum variableDeclarations = ForEachIndexPosition!(i+1).variableDeclarations;
                enum gotoDeniedOnInvalid = ForEachIndexPosition!(i+1).gotoDeniedOnInvalid;
                enum fixupIndices = ForEachIndexPosition!(i+1).fixupIndices;
            }
        }else{
            enum getNodePositions = "";
            enum variableDeclarations = "";
            enum gotoDeniedOnInvalid = "";
            enum fixupIndices = "";
        }
    }

    bool _Replace(ThisNode* node, Value value){
        mixin(ForEachIndexPosition!0 .variableDeclarations);
        mixin(ForEachIndexPosition!0 .getNodePositions);
        Value old = node.value;
        node.value = value;
        {
            mixin(ForEachIndexPosition!0 .gotoDeniedOnInvalid);
            mixin(ForEachIndexPosition!0 .fixupIndices);
        }
        return true;
denied:
        node.value = old;
        return false;
    }

/*
Perform mod on node.value and perform any necessary fixups to this container's
indices. mod may be of the form void mod(ref Value), in which case mod directly modifies the value in node. If the result of mod violates any index' invariant,
the node is removed from the container.
Preconditions: mod is a callable of the form void mod(ref Value)
Complexity: $(BIGOH m(n))
*/
    void _Modify(Modifier)(ThisNode* node, Modifier mod){
        mixin(ForEachIndexPosition!0 .variableDeclarations);
        mixin(ForEachIndexPosition!0 .getNodePositions);
        mod(node.value);
        mixin(ForEachIndexPosition!0 .gotoDeniedOnInvalid);
        mixin(ForEachIndexPosition!0 .fixupIndices);
        return;
denied:
        _RemoveAll(node);
    }

    template ForEachClear(size_t i){
        static if(i < IndexedBy.Indices.length){
            enum string result = Replace!(q{
                index!$i ._ClearIndex();
            }, "$i", i) ~ ForEachClear!(i+1).result;
        }else enum string result = "";
    }

    void _Clear(){
        auto r = index!0 .opSlice();
        while(!r.empty){
            ThisNode* node = r.front_node;
            r.popFront();
            dealloc(node);
        }
        mixin(ForEachClear!0 .result);
        node_count = 0;
    }

    template ForEachCheck(size_t i){
        static if(i < IndexedBy.Indices.length){
            enum result = Replace!(q{
                index!($i)._Check();
            },"$i", i) ~ ForEachCheck!(i+1).result;
        }else{
            enum result = "";
        }
    }

    void check(){
        mixin(ForEachCheck!(0).result);
    }

    template ForEachAlias(size_t N,size_t index, alias X){
        alias X.Inner!(ThisNode,Value, ValueView,N,Allocator).Index!() Index;
        static if(Index.container_aliases.length > index){
            enum aliashere = NAliased!(Index.container_aliases[index][0],
                    Index.container_aliases[index][1], N);
            enum result = aliashere ~ "\n" ~ ForEachAlias!(N,index+1, X).result;
        }else{
            enum result = "";
        }
    }


    @property auto to_range(size_t N, Range0)(Range0 r)
    if(RangeIndexNo!Range0 != -1){
        static if(N == RangeIndexNo!Range0){
            return r;
        }else{
            return index!N.fromNode(r.front_node);
        }
    }

    private template RangeIndexNo(R){
        template IndexNoI(size_t i){
            static if(i == IndexedBy.Indices.length){
                enum size_t IndexNoI = -1;
            }else static if(index!(i).IsMyRange!(R)){
                enum size_t IndexNoI = i;
            }else{
                enum IndexNoI = IndexNoI!(i+1);
            }
        }
        enum size_t RangeIndexNo = IndexNoI!(0);
    }
}

/// simple Slot implementation
mixin template Slots() {
    void delegate()[] slots;

    void connect(void delegate() slot){
        slots ~= slot;
    }
    void disconnect(void delegate() slot){
        size_t index = slots.length;
        foreach(i, slot1; slots){
            if(slot is slot1){
                index = i;
                moveAll(slots[i+1 .. $], slots[i .. $-1]);
                slots.length-=1;
                break;
            }
        }
    }
    void emit(){
        foreach(slot; slots){
            slot();
        }
    }
}

import std.stdio;

int[] arr(Range)(Range r){
    int[] result = new int[](r.length);
    size_t j = 0;
    foreach(e; r){
        result[j++] = e;
    }
    return result;
}

struct S1{
    string _s;
    int _i;
    void delegate() slot = null;

    @property string s()const{ return _s;}
    @property void s(string s_){ _s = s_; emit(); }

    @property int i()const{ return _i;}
    @property void i(int i_){ _i = i_; }

    void emit(){
        if (slot) slot();
    }

    void connect(void delegate() slot){ this.slot = slot; }
    void disconnect(void delegate() slot){
        if(this.slot is slot) this.slot = null;
    }

    string toString0()const{
        return format("%s: %s", s, i);
    }
}

version(TestMultiIndex)
void main(){
    alias MultiIndexContainer!(S1,
            IndexedBy!(Sequenced!(),
                OrderedUnique!("a.s")
                ),
            ValueChangedSlots!(ValueSignal!(1))) C;

    C i = C.create();

    alias MultiIndexContainer!(const(S1),
        IndexedBy!(OrderedUnique!("a.s"))
        ) CCC;
        CCC c2 = new CCC;
        c2.insert(cast(const)S1("abc", 22));
        pragma(msg, typeof(c2[]));
        pragma(msg, ElementType!(typeof(c2[])));
        foreach(const(S1) thing; c2[]) {
        }

        auto pr = PSR(c2[]);
        c2.replace(pr.front, const(S1)("def", 44));
}
