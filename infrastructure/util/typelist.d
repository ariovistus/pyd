module util.typelist;

template Join(string delimit, T...) {
        static if(T.length == 0) {
            enum Join = "";
        }else static if(T.length == 1) {
            enum Join =  T[0];
        }else {
            enum Join = T[0] ~ delimit ~ Join!(delimit,T[1..$]);
        }
}

// I rather like the whole algorithm("isThing(a)") shtick.
// useful for templates too?
template Pred(string pred) {
    template Pred(Stuff...)
    if(Stuff.length == 1)
    {
        alias A = Stuff[0];
        alias Pred = Alias!(mixin(pred));
    }
}

//Stolen from phobos:
/*
 * With the builtin alias declaration, you cannot declare
 * aliases of, for example, literal values. You can alias anything
 * including literal values via this template.
 */
// symbols and literal values
template Alias(alias a)
{
    static if (__traits(compiles, { alias x = a; }))
        alias Alias = a;
    else static if (__traits(compiles, { enum x = a; }))
        enum Alias = a;
    else
        static assert(0, "Cannot alias " ~ a.stringof);
}
// types and tuples
template Alias(a...)
{
    alias Alias = a;
}

unittest
{
    enum abc = 1;
    static assert(__traits(compiles, { alias a = Alias!(123); }));
    static assert(__traits(compiles, { alias a = Alias!(abc); }));
    static assert(__traits(compiles, { alias a = Alias!(int); }));
    static assert(__traits(compiles, { alias a = Alias!(1,abc,int); }));
}
