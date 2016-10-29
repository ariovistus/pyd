import pyd.pyd;
import marscamera_c_interface;

extern (C) void PydMain() {
        // Def! calls must happen before module_init
        def!(__attach, PyName!"attach")();
        def!(__detach, PyName!"detach")();
        def!(__camera_find, PyName!"find")();
        def!(__camera_close, PyName!"close")();
        def!(__acquire, PyName!"acquire")();
        def!(__get_image, PyName!"getImage")();

        // initialise the module
        module_init();
        // !class_wrap calls must happen after module_init
}
