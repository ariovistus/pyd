module util.replace;
import std.algorithm;
import std.metastrings;

template Replace(string base, T...){
    static assert(T.length % 2 == 0);

    alias NextAt!(base,T) N;
    static if(N.ti == -1){
        enum Replace = base;
    }else{
        enum Replace = base[0 .. N.at] ~ toStringNow!(T[N.ti+1]) ~ 
            Replace!(base[N.at + T[N.ti].length .. $], T);
    }
}

template NextAt(string base, T...){
    static assert(T.length % 2 == 0);
    static if(T.length == 0){
        enum size_t at = base.length;
        enum size_t ti = -1;
    }else{
        enum size_t _at1 = countUntil(base, T[$-2]);
        static if(_at1 == 0){
            enum at = _at1;
            enum ti = T.length-2;
        }else{
            alias NextAt!(base, T[0 .. $-2]) N2;
            static if(_at1 < N2.at){
                enum size_t at = _at1;
                enum ti = T.length-2;
            }else{
                enum at = N2.at;
                enum ti = N2.ti;
            }
        }
    }
}

