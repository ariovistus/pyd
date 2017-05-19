module error1;

import pyd.pyd;

class Test {
    this(immutable int) {
    }
}
extern(C) void PydMain() {
    // pyd should output a useful error message here
    wrap_class!(Test, Init!(int));
    module_init();
}
