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
import std.metastrings;
import std.algorithm;
import std.range;

string objToStr(Object o) {
    return o.toString();
}
public import meta.Nameof : symbolnameof, prettytypeof, prettynameof;

import std.conv;
alias to!string toString;
public import std.traits : ParameterTypeTuple, ReturnType;
import std.traits;

template minNumArgs_impl(alias fn, fnT) {
    alias ParameterTypeTuple!(fnT) Params;
    Params params;// = void;

    template loop(size_t i = 0) {
        static assert (i <= Params.length);

        static if (__traits(compiles,fn(params[0..i].init))) {
            enum size_t res = i;
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
    enum size_t minArgs = minNumArgs_impl!(fn, fnT).res;
}

template maxArgs(alias fn, fn_t = typeof(&fn)) {
    alias variadicFunctionStyle!fn vstyle;
    alias ParameterTypeTuple!fn ps;
    enum bool hasMax = vstyle == Variadic.no;
    enum size_t max = ps.length;
}

bool supportsNArgs(alias fn, fn_t = typeof(&fn))(size_t n) {
    if(n < minArgs!(fn,fn_t)) {
        return false;
    }
    alias variadicFunctionStyle!fn vstyle;
    alias ParameterTypeTuple!fn ps;
    static if(vstyle == Variadic.no) {
        if(n > ps.length) return false;
        if(n == ps.length && n == 0) return true;
        foreach(i,_p; ps) {
            if(__traits(compiles, fn(ps[0 .. i+1].init)) && i+1 == n) {
                return true;
            }
        }
        return false;
    }else static if(vstyle == Variadic.c) {
        return true;
    }else static if(vstyle == Variadic.d) {
        return true;
    }else static if(vstyle == Variadic.typesafe) {
        return true;
    }else static assert(0);
}

template getparams(alias fn) {
    enum raw_str = typeof(fn).stringof;
    enum ret_str = ReturnType!fn.stringof;
    static assert(raw_str.startsWith(ret_str));
    enum noret_str = raw_str[ret_str.length .. $];
    enum open_p = countUntil(noret_str, "(");
    static assert(open_p != -1);
    enum close_p = countUntil(retro(noret_str), ")");
    static assert(close_p != -1);
    enum getparams = noret_str[open_p+1 .. $-1-close_p];

}
