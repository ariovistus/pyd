
extern(C) int wiz(double d) {
    return 3 + cast(int) d;
}

// stuff in infrastructure/d/python_so_boilerplate

extern(C) shared bool _D2rt6dmain212_d_isHaltingOb;
alias _D2rt6dmain212_d_isHaltingOb _d_isHalting;
extern(C) {

    void rt_init();
    void rt_term();

    void _init() {
        rt_init();
    }

    void _fini() {
            import std.c.stdio;
            printf("_fini\n");
        if(!_d_isHalting){
            printf("rt_term\n");
            rt_term();
        }
    }

}

// (*^*&%^(* druntime

extern(C) void _Dmain(){}
