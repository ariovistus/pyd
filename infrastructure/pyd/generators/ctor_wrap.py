f = open('ctor_wrap.txt', 'w')

template = "d_type!(Ctor.arg%s)(PyTuple_GetItem(args, %s))"

for i in range(2, 11):
    f.write("        } else static if (Ctor.ARGS == %s) {\n" % i)
    f.write("            T t = new T(\n")
    for j in range(i):
        f.write("                " + template % (j+1, j))
        if j < i-1:
            f.write(',')
        f.write('\n')
    f.write("            );\n")
f.write ("        }")
