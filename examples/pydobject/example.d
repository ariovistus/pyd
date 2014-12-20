import std.stdio;
import pyd.pyd, pyd.embedded;

void main() {
    py_init();

    PydObject random = py_eval("Random()", "random");
    random.method("seed", 234);
    int randomInt = random.randrange(1, 100).to_d!int();
    PydObject otherInt = random.randrange(200, 250);

    writeln("result: ", otherInt + randomInt);

    PydObject ints = py_eval("[randint(1, 9) for i in range(20)]", "random");

    write("[");
    foreach(num; ints) {
        write(num);
        write(", ");
    }
    writeln("]");
}
