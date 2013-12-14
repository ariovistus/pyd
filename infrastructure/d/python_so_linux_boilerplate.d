// This file requires the .so be compiled with '-nostartfiles'.
// Also note that this is inferior to the Windows version: it does not call the
// static constructors or unit tests. As far as I can tell, this can't be done
// until Phobos is updated to explicitly allow it.
extern(C) shared bool _D2rt6dmain212_d_isHaltingOb;
alias _D2rt6dmain212_d_isHaltingOb _d_isHalting;
extern(C) {

    void rt_init();
    void rt_term();

    version(LDC) {
        pragma(LDC_global_crt_ctor)
            void hacky_init() {
                rt_init();
            }

        pragma(LDC_global_crt_dtor)
            void hacky_fini() {
                if(!_d_isHalting){
                    rt_term();
                }
            }
    }else{
        void hacky_init() {
            rt_init();
        }

        void hacky_fini() {
            if(!_d_isHalting){
                rt_term();
            }
        }
    }

} /* extern(C) */
