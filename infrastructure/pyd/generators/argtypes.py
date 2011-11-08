MAX_ARGS = 10

import sys
old_stdout = sys.stdout
sys.stdout = open('argtypes.txt', 'w')

def arglist(n):
    parts = []
    for i in range(n):
        parts.append(', A%s' % i)
    return "".join(parts)

def typeidList(n):
    parts = []
    for i in range(n):
        parts.append('typeid(A%s)' % i)
    return ", ".join(parts)

for i in range(MAX_ARGS+1):
    print "public"
    print "template ArgTypes(Tr%s) {" % arglist(i)
    print "    TypeInfo[] ArgTypes(Tr function(%s) fn) {" % arglist(i)[2:]
    print "        return arrayOf!(TypeInfo)(%s);" % typeidList(i)
    print "    }"
    print "}"
    print

sys.stdout = old_stdout
