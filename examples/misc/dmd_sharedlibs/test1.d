import std.c.stdio;
// stuff in our library

static this() {
    printf("yawn. stretch.");
}

extern(C) int foo(int i) {
    return "abc".dup.length + i+1;
}

// stuff in infrastructure/d/python_so_boilerplate

extern(C) shared bool _D2rt6dmain212_d_isHaltingOb;
alias _D2rt6dmain212_d_isHaltingOb _d_isHalting;
extern(C) {

    void rt_init();
    void rt_term();

    void my_init() {
        rt_init();
    }

    void my_fini() {
        if(!_d_isHalting){
            rt_term();
        }
    }

}

// (*^*&%^(* druntime

extern(C) void _Dmain(){}
