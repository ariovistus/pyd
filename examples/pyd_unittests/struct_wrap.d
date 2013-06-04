import pyd.pyd, pyd.embedded;

struct Foo1{
    int i;
    int j;
    int k;

    this(int _i, int _j, int _k) {
        i=_i; j=_j; k=_k;
    }

    int bar() {
        return i+j*k;
    }
}

static this() {
    on_py_init({
    add_module!(ModuleName!"testing")();
    });
    on_py_init({
    wrap_struct!(
            Foo1,
            ModuleName!"testing",
            Init!(int,int,int),
            Member!("i"),
            Member!("j", Mode!"r"),
            Member!("k", Mode!"w"),
            Def!(Foo1.bar),
            )();
    }, PyInitOrdering.After);

    py_init();
}


unittest {
    py_stmts(q"{
foo1 = Foo1(2,3,4);
assert foo1.i == 2
            }","testing");
}

void main(){}
