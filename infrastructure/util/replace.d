module util.replace;
import std.metastrings;

template Replace(string base, T...) 
{
    import std.algorithm;
    static assert(T.length % 2 == 0);
    template NextAt(string base, string longest_spec, 
            size_t _at0, size_t _ti0, T...)
    {
        static assert(T.length % 2 == 0);
        static if(T.length == 0)
        {
            static if(_at0 == -1) 
            {
                enum size_t at = base.length;
                enum size_t ti = -1;
            }
            else
            {
                enum at = _at0;
                enum ti = _ti0;
            }
        }
        else
        {
            enum size_t _at1 = countUntil(base, T[$-2]);
            static if(_at1 < _at0 || 
                    _at1 == _at0 && T[$-2].length > longest_spec.length)
            {
                alias NextAt!(base, T[$-2], _at1, T.length-2,T[0 .. $-2]) N2;
            }
            else 
            {
                alias NextAt!(base,longest_spec,_at0,_ti0,T[0 .. $-2]) N2;
            }
            enum at = N2.at;
            enum ti = N2.ti;
        }
    }


    alias NextAt!(base,"",-1,-1,T) N;
    static if(N.ti == -1)
        enum Replace = base;
    else
        enum Replace = base[0 .. N.at] ~ toStringNow!(T[N.ti+1]) ~ 
            Replace!(base[N.at + T[N.ti].length .. $], T);
}

