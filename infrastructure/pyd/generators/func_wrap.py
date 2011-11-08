f = open('func_wrap.txt', 'w')

template = "d_type!(ArgType!(fn_t, %s))(PyTuple_GetItem(args, %s))"

for i in range(1, 11):
    f.write(" " * 8 + "} static if (MIN_ARGS <= %s && MAX_ARGS >= %s) {\n" % (i, i))
    f.write(" " * 12 + "if (ARGS == %s) {\n" % i)
    f.write(" " * 16 +    "static if (is(RetType : void)) {\n")
    f.write(" " * 20 +        "fn(\n")
    for j in range(i):
        f.write(" " * 24 + template % (j+1, j))
        if j < i-1:
            f.write(',')
        f.write('\n')
    f.write(" " * 20 +        ");\n")
    f.write(" " * 20 +        "Py_INCREF(Py_None);\n")
    f.write(" " * 20 +        "ret = Py_None;\n")
    f.write(" " * 16 +    "} else {\n")
    f.write(" " * 20 +        "ret = _py( fn(\n")
    for j in range(i):
        f.write(" " * 24 + template % (j+1, j))
        if j < i-1:
            f.write(',')
        f.write('\n')
    f.write(" " * 20 +        ") );\n")
    f.write(" " * 16 +    "}\n")
    f.write(" " * 12 + "}\n")
f.write (" " * 8 + "}")
