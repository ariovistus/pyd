version(linux) {
    string boilerplateMixinStr() {
        // Note that this is inferior to the Windows version: it does not call the
        // static constructors or unit tests. As far as I can tell, this can't be done
        // until Phobos is updated to explicitly allow it.
        return q{
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
        };
    }

} else version(Windows) {

    string boilerplateMixinStr() {
        return q{
import core.sys.windows.windows: HINSTANCE, BOOL, ULONG, LPVOID;

__gshared HINSTANCE g_hInst;

extern (Windows)
BOOL DllMain(HINSTANCE hInstance, ULONG ulReason, LPVOID pvReserved)
{
    import core.sys.windows.windows;
    import core.sys.windows.dll;
    switch (ulReason)
    {
	case DLL_PROCESS_ATTACH:
	    g_hInst = hInstance;
	    dll_process_attach( hInstance, true );
	    break;

	case DLL_PROCESS_DETACH:
	    dll_process_detach( hInstance, true );
	    break;

	case DLL_THREAD_ATTACH:
	    dll_thread_attach( true, true );
	    break;

	case DLL_THREAD_DETACH:
	    dll_thread_detach( true, true );
	    break;

        default:
    }
    return true;
}
        };
    }
}
