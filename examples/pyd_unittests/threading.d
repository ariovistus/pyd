import pyd.pyd, pyd.embedded;
import std.stdio;
import std.range;
import std.concurrency;
import core.thread;
import core.time;

shared static this() {
    py_init();
}

void non_python_block() {
    try{
        auto dg = {
            receive(
                    (string s) { writeln(s); }
                   );
        };
        auto py_dg = py(dg);
        alias py_def!(
                "def a(fun):\n"
                " fun()",
                "sys",
                void function(PydObject)) Caller;
        Caller(py_dg);
    }catch(Throwable t) {
        writeln(t.toString());
    }
}

void python_stuff1() {
    py_stmts(
            "for i in range(3):\n"
            " print i"
            );
}

unittest {

    Tid tid = spawn(&non_python_block);
    Thread.sleep(dur!"seconds"(1));
    spawn(&python_stuff1);
    Thread.sleep(dur!"seconds"(1));
    send(tid, "finito!");
    thread_joinAll();
}


void main() {}
