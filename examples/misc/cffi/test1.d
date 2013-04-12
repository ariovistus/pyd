import std.exception;
import std.typetuple;
import std.conv;
import std.traits;
import std.string;

extern(C) int int_test(int i, int j) {
    return 2*i + 3*j - 5;
}

extern(C) double float_test(double d, double e) {
    return 2.5 * d + 1.25 * e;
}

extern(C) string str_test(string s, string t) {
    return format("I believe in %s, and banging two %s together!", s, t);
}
