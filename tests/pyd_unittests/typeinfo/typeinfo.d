
import pyd.util.typeinfo;

unittest {
    static assert(constness!Object == Constness.Mutable);
    static assert(constness!(const(Object)) == Constness.Const);
    static assert(constness!(immutable(Object)) == Constness.Immutable);
}

class X {
    void mut() {
    }
    void cnst() const {
    }
    void immut() immutable {
    }
    void wildcard() inout {
    }
}
unittest {
    static assert(constness!(typeof(X.mut)) == Constness.Mutable);
    static assert(constness!(typeof(X.cnst)) == Constness.Const);
    static assert(constness!(typeof(X.immut)) == Constness.Immutable);
    static assert(constness!(typeof(X.wildcard)) == Constness.Wildcard);

    // for a pointer to a function, we look at the mutability of the pointer,
    // not the function. should we?
    static assert(constness!(typeof(&X.mut)) == Constness.Mutable);
    static assert(constness!(typeof(&X.cnst)) == Constness.Mutable);
    static assert(constness!(typeof(&X.immut)) == Constness.Mutable);
    static assert(constness!(typeof(&X.wildcard)) == Constness.Mutable);
}

void main() {}
