import sys
old_stdout = sys.stdout
sys.stdout = open('op_wrap.txt', 'w')

binops = [
    'Add', 'Sub', 'Mul', 'Div', 'Mod', 'And', 'Or', 'Xor', 'Shl', 'Shr',
    'UShr', 'Cat', 'AddAssign', 'SubAssign', 'MulAssign', 'DivAssign',
    'ModAssign', 'AndAssign', 'OrAssign', 'XorAssign', 'ShlAssign', 'ShrAssign',
    'UShrAssign', 'CatAssign', 'In',
]

uniops = [
    'Neg', 'Pos', 'Com',
]

bin_template = """\
template op%s_wrap(T) {
    static if (is(typeof(&T.op%s))) {
        const binaryfunc op%s_wrap = &opfunc_binary_wrap!(T, T.op%s).func;
    } else {
        const binaryfunc op%s_wrap = null;
    }
}

"""

uni_template = """\
template op%s_wrap(T) {
    static if (is(typeof(&T.op%s))) {
        const unaryfunc op%s_wrap = &opfunc_unary_wrap!(T, T.op%s).func;
    } else {
        const unaryfunc op%s_wrap = null;
    }
}
"""

for op in binops:
    print bin_template % (op, op, op, op, op)

for op in uniops:
    print uni_template % (op, op, op, op, op)

sys.stdout = old_stdout
