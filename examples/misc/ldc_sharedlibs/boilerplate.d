extern(C) shared bool _D2rt6dmain212_d_isHaltingOb;
alias _D2rt6dmain212_d_isHaltingOb _d_isHalting;
extern(C) {

    void rt_init();
    void rt_term();

    pragma(LDC_global_crt_ctor)
    void my_init() {
        rt_init();
    }

    pragma(LDC_global_crt_dtor)
    void my_fini() {
        if(!_d_isHalting){
            rt_term();
        }
    }

}

// (*^*&%^(* druntime

extern(C) void _Dmain(){}
