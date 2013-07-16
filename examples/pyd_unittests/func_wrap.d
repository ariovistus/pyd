
import pyd.pyd, pyd.embedded;
import pyd.func_wrap;
import core.vararg;

void foo0() {
}

void foo1(int i, int j) {
}
void foo2(int i, double j = 2.0) {
}
void foo3(...) {
}
void foo4(int[] i...) {
}

void foo5(int i=1, double d = 2.0) {
}

class Foo1{
    this(int i, int j) {
    }
}
class Foo2{
    this(int i, double j = 1.0) {
    }
}
class Foo3{
    this(...){
    }
}
class Foo4{
    this(int[] i...){
    }
}

class Foo5{
    this(int i, double j = 1.0, double k = 4.5, double L = 6.325){
    }
}

unittest {
    static assert(getparams!(foo1,"A","B") == "A[0] i, A[1] j");
    static assert(getparams!(foo2, "A","B") == "A[0] i, A[1] j = B[1]");
    static assert(getparams!(foo3, "A","B") == "...");
    static assert(getparams!(foo4, "A","B") == "A[0] i...");
    auto fn = &call_ctor!(Foo2, Init!(int, double)).func;
    //pragma(msg, typeof(fn));
    //fn(1);
    static assert(minArgs!(call_ctor!(Foo2, Init!(int, double)).func) == 1);
    auto fn2 = &call_ctor!(Foo5, Init!(int, double, double, double)).func;
    static assert(minArgs!(call_ctor!(Foo5, Init!(int, double, double, double)).func) == 1);

    static assert(minArgs!foo1 == 2);
    static assert(minArgs!foo2 == 1);
    static assert(minArgs!foo3 == 0);
    static assert(minArgs!foo4 == 0);

    assert(supportsNArgs!foo0(0));
    assert(!supportsNArgs!foo0(1));
    assert(!supportsNArgs!foo0(2));
    assert(!supportsNArgs!foo0(3));

    assert(!supportsNArgs!foo1(0));
    assert(!supportsNArgs!foo1(1));
    assert(supportsNArgs!foo1(2));
    assert(!supportsNArgs!foo1(3));

    assert(!supportsNArgs!(Foo1.__ctor)(0));
    assert(!supportsNArgs!(Foo1.__ctor)(1));
    assert(supportsNArgs!(Foo1.__ctor)(2));
    assert(!supportsNArgs!(Foo1.__ctor)(3));

    assert(!supportsNArgs!foo2(0));
    assert(supportsNArgs!foo2(1));
    assert(supportsNArgs!foo2(2));
    assert(!supportsNArgs!foo2(3));

    assert(!supportsNArgs!(Foo2.__ctor)(0));
    assert(supportsNArgs!(Foo2.__ctor)(1));
    assert(supportsNArgs!(Foo2.__ctor)(2));
    assert(!supportsNArgs!(Foo2.__ctor)(3));

    assert(supportsNArgs!foo3(0));
    assert(supportsNArgs!foo3(1));
    assert(supportsNArgs!foo3(2));
    assert(supportsNArgs!foo3(3));

    assert(supportsNArgs!foo4(0));
    assert(supportsNArgs!foo4(1));
    assert(supportsNArgs!foo4(2));
    assert(supportsNArgs!foo4(3));

    assert(supportsNArgs!foo5(0));
    assert(supportsNArgs!foo5(1));
    assert(supportsNArgs!foo5(2));
    assert(!supportsNArgs!foo5(3));

    assert(!supportsNArgs!(Foo5.__ctor)(0));
    assert(supportsNArgs!(Foo5.__ctor)(1));
    assert(supportsNArgs!(Foo5.__ctor)(2));
    assert(supportsNArgs!(Foo5.__ctor)(3));
    assert(supportsNArgs!(Foo5.__ctor)(4));
    assert(!supportsNArgs!(Foo5.__ctor)(5));
}

import std.stdio;
enum string msg = import("important_message.txt");

void main() {
    writeln(msg);
}
