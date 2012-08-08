/*
Copyright (c) 2006 Kirk McDonald

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

// This module abstracts out all of the uses of Phobos, Tango, and meta, easing
// the ability to switch between Phobos and Tango arbitrarily.
module pyd.lib_abstract;

string objToStr(Object o) {
    return o.toString();
}
public import meta.Nameof : symbolnameof, prettytypeof, prettynameof;

import std.conv;
alias to!string toString;
public import std.traits : ParameterTypeTuple, ReturnType;

template minNumArgs_impl(alias fn, fnT) {
    alias ParameterTypeTuple!(fnT) Params;
    Params params;// = void;

    template loop(int i = 0) {
        static assert (i <= Params.length);

        static if (is(typeof(fn(params[0..i])))) {
            enum int res = i;
        } else {
            alias loop!(i+1).res res;
        }
    }

    alias loop!().res res;
}
/**
  Finds the minimal number of arguments a given function needs to be provided
 */
template minArgs(alias fn, fnT = typeof(&fn)) {
    enum int minArgs = minNumArgs_impl!(fn, fnT).res;
}
