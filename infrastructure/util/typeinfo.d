/*
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
module util.typeinfo;

import std.traits;
import std.compiler;

enum Constness {
    Mutable,
    Const,
    Immutable,
    Wildcard
}

string constness_ToString(Constness c) {
    switch(c){
        case Constness.Mutable:
            return "mutable";
        case Constness.Const:
            return "const";
        case Constness.Immutable:
            return "immutable";
        case Constness.Wildcard:
            return "inout";
        default:
            assert(0);
    }
}

template constness(T) {
    static if(is(T == immutable)) {
        enum constness = Constness.Immutable;
    }else static if(is(T == const)) {
        enum constness = Constness.Const;
    }else static if(is(T == inout)) {
        enum constness = Constness.Wildcard;
    }else {
        enum constness = Constness.Mutable;
    }
}

bool constCompatible(Constness c1, Constness c2) {
    return c1 == c2 ||
        c1 == Constness.Const && c2 != Constness.Wildcard ||
        c2 == Constness.Const && c1 != Constness.Wildcard;
}

template ApplyConstness(T, Constness constness) {
    alias Unqual!T Tu;
    static if(constness == Constness.Mutable) {
        alias Tu ApplyConstness;
    }else static if(constness == Constness.Const) {
        alias const(Tu) ApplyConstness;
    }else static if(constness == Constness.Wildcard) {
        alias inout(Tu) ApplyConstness;
    }else static if(constness == Constness.Immutable) {
        alias immutable(Tu) ApplyConstness;
    }else {
        static assert(0);
    }
}

template ApplyConstness2(T, Constness constness) {
    alias Unqual!T Tu;
    static if(constness == Constness.Mutable) {
        alias Tu ApplyConstness2;
    }else static if(constness == Constness.Const) {
        alias const(Tu) ApplyConstness2;
    }else static if(constness == Constness.Wildcard) {
        alias Tu ApplyConstness2;
    }else static if(constness == Constness.Immutable) {
        alias immutable(Tu) ApplyConstness2;
    }else {
        static assert(0);
    }
}

string attrs_to_string(uint attrs) {
    string s = "";
    with(FunctionAttribute) {
        if(attrs & pure_) s ~= " pure";
        if(attrs & nothrow_) s ~= " nothrow";
        if(attrs & ref_) s ~= " ref";
        if(attrs & property) s ~= " @property";
        if(attrs & trusted) s ~= " @trusted";
        if(attrs & safe) s ~= " @safe";
        if(attrs & nogc) s ~= " @nogc";
        static if(version_major == 2 && version_minor >= 67) {
            if(attrs & return_) s ~= " return";
        }
    }
    return s;
}

// what U should be so 'new U' returns a T
template NewParamT(T) {
    static if(isPointer!T && is(PointerTarget!T == struct))
        alias PointerTarget!T NewParamT;
    else alias T NewParamT;
}

template StripSafeTrusted(F) {
    enum attrs = functionAttributes!F ;
    enum desired_attrs = attrs & ~FunctionAttribute.safe & ~FunctionAttribute.trusted;
    enum linkage = functionLinkage!F;
    alias SetFunctionAttributes!(F, linkage, desired_attrs) unqual_F;
    static if(isFunctionPointer!F) {
        enum constn = constness!(PointerTarget!F);
        alias ApplyConstness!(PointerTarget!unqual_F, constn)* StripSafeTrusted;
    }else static if(isDelegate!F) {
        enum constn = constness!(F);
        alias ApplyConstness!(unqual_F, constn) StripSafeTrusted;
    }else{
        enum constn = constness!(F);
        alias ApplyConstness!(unqual_F, constn) StripSafeTrusted;
    }


}

class Z {
    void a() immutable
    {
    }
}
//static assert(is(StripSafeTrusted!(typeof(&Z.a)) == typeof(&Z.a) ));
//static assert(is(StripSafeTrusted!(typeof(&Z.init.a)) == typeof(&Z.init.a) ));
import std.traits : isCallable;
import std.typetuple : TypeTuple;
template WorkaroundParameterDefaults(func...)
	if (func.length == 1 && isCallable!func)
{
    static if (is(FunctionTypeOf!(func[0]) PT == __parameters))
    {
        template Get(size_t i)
        {
            // workaround scope escape check, see
            // https://issues.dlang.org/show_bug.cgi?id=16582
            // should use return scope once available
            enum get = (PT[i .. i + 1] __args) @trusted
			{
                // If __args[0] is lazy, we force it to be evaluated like this.
                auto __pd_value = __args[0];
                auto __pd_val = &__pd_value; // workaround Bugzilla 16582
                return *__pd_val;
            };
            static if (is(typeof(get())))
                enum Get = get();
            else
                alias Get = void;
                // If default arg doesn't exist, returns void instead.
        }
    }
    else
    {
        static assert(0, func[0].stringof ~ "is not a function");

        // Define dummy entities to avoid pointless errors
        template Get(size_t i) { enum Get = ""; }
        alias PT = TypeTuple!();
    }

    template Impl(size_t i = 0)
    {
        static if (i == PT.length)
            alias Impl = TypeTuple!();
        else
            alias Impl = TypeTuple!(Get!i, Impl!(i + 1));
    }

    alias WorkaroundParameterDefaults = Impl!();
}

@safe unittest
{
    int foo(int num, string name = "hello", int[] = [1,2,3], lazy int x = 0);
    static assert(is(WorkaroundParameterDefaults!foo[0] == void));
    static assert(   WorkaroundParameterDefaults!foo[1] == "hello");
    static assert(   WorkaroundParameterDefaults!foo[2] == [1,2,3]);
    static assert(   WorkaroundParameterDefaults!foo[3] == 0);
}

@safe unittest
{
    alias PDVT = WorkaroundParameterDefaults;

    void bar(int n = 1, string s = "hello"){}
    static assert(PDVT!bar.length == 2);
    static assert(PDVT!bar[0] == 1);
    static assert(PDVT!bar[1] == "hello");
    static assert(is(typeof(PDVT!bar) == typeof(TypeTuple!(1, "hello"))));

    void baz(int x, int n = 1, string s = "hello"){}
    static assert(PDVT!baz.length == 3);
    static assert(is(PDVT!baz[0] == void));
    static assert(   PDVT!baz[1] == 1);
    static assert(   PDVT!baz[2] == "hello");
    static assert(is(typeof(PDVT!baz) == typeof(TypeTuple!(void, 1, "hello"))));

    // bug 10800 - property functions return empty string
    @property void foo(int x = 3) { }
    static assert(PDVT!foo.length == 1);
    static assert(PDVT!foo[0] == 3);
    static assert(is(typeof(PDVT!foo) == typeof(TypeTuple!(3))));

    struct Colour
    {
        ubyte a,r,g,b;

        static immutable Colour white = Colour(255,255,255,255);
    }
    void bug8106(Colour c = Colour.white) {}
    //pragma(msg, PDVT!bug8106);
    static assert(PDVT!bug8106[0] == Colour.white);
    void bug16582(scope int* val = null) {}
    static assert(PDVT!bug16582[0] is null);
}
