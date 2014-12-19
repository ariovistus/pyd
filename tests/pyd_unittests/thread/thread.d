import pyd.thread;
import std.compiler;
import core.thread;

static if(version_minor < 67) {
    unittest {
        auto thread = Thread.getThis();
        auto addr = getThreadAddr(thread);
        auto thread2 = thread_findByAddr(addr);
        assert(thread2 == thread);
    }
}

void main() {}
