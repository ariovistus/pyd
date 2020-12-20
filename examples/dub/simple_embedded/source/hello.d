module hello;

import std.stdio;
import pyd.pyd, pyd.embedded;

shared static this() {
    py_init();
}

void main() {
    writeln(py_eval!string("'1 + %s' % 2"));

    auto c = py_eval("complex(2,-1)");
    /* https://github.com/ariovistus/pyd/pull/143#issuecomment-748557221
       there is no way to get opDispatch to distinguish between obj.property and obj.property().
       So we have this kind of compromise where no parameters are treated as obj.property and
       presence of parameters are treated as a method call.
     */
    auto hm = c.__hash__;      // return <method-wrapper '__hash__' of complex object at 0x7fa8c49897d0>
    auto hr = c.__hash__()();  // return the result of the function call.
    writeln(c);
    writeln(hm);
    writeln(hr);
}
