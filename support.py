__all__ = ('setup', 'Extension')

from pyd import patch_distutils # Cause distutils to be hot-patched.
import sys, os, os.path

from distutils.core import setup as base_setup, Extension as std_Extension, Command
from distutils.util import get_platform
from distutils.dep_util import newer_group
from distutils import log
from distutils.errors import DistutilsOptionError

class Extension(std_Extension):
    def __init__(self, *args, **kwargs):
        if 'define_macros' in kwargs or 'undef_macros' in kwargs:
            raise DistutilsOptionError('D does not support macros, so the'
                ' "define_macros" and "undef_macros" arguments are not'
                ' supported.  Instead, consider using the "Version Condition"'
                ' and "Debug Condition" conditional compilation features'
                ' documented at http://www.digitalmars.com/d/version.html'
                '\n  Version flags can be passed to the compiler via the'
                ' "version_flags" keyword argument to DExtension; debug flags'
                ' via the "debug_flags" keyword argument.  For example, when'
                ' used with the DMD compiler,'
                '\n    DExtension(..., version_flags=["a", "b"])'
                '\nwill cause'
                '\n    -version=a -version=b'
                '\nto be passed to the compiler.'
              )

        # If the user has requested any version_flags or debug_flags, we use
        # the distutils 'define_macros' keyword argument to carry them (they're
        # later unpacked in the dcompiler module).

        self.version_flags = kwargs.pop('version_flags',[])
        self.debug_flags = kwargs.pop('debug_flags',[])

        if 'raw_only' in kwargs:
            kwargs['with_pyd'] = False
            kwargs['with_main'] = False
            del kwargs['raw_only']
        self.with_pyd  = kwargs.pop('with_pyd', True)
        self.build_deimos = kwargs.pop('build_deimos', False)
        self.with_main = kwargs.pop('with_main', True)
        self.pyd_optimize = kwargs.pop('optimize', False)
        self.d_unittest = kwargs.pop('d_unittest', False)
        self.d_property = kwargs.pop('d_property', False)
        self.d_lump = kwargs.pop('d_lump', False)
        self.string_imports = kwargs.pop('string_imports', [])
        if self.with_main and not self.with_pyd:
            # The special PydMain function should only be used when using Pyd
            self.with_main = False

        std_Extension.__init__(self, *args, **kwargs)


class build_pyd_embedded_exe(Command):
    description = "Build a D application that embeds python with Pyd"

    user_options = [
        ('compiler=', 'c',
         "specify the compiler type"),
        ("optimize", "O", "Ask the D compiler to optimize the generated code, at the expense of"
                " safety features such as array bounds checks."),
        ('debug', 'g',
         "compile extensions and libraries with debugging information"),
        ('force', 'f',
         "forcibly build everything (ignore file timestamps)"),
        ("print-flags", None, "Don't build, just print out version flags for pyd") ]

    boolean_options = ['print-flags', 'debug', 'force']

    def initialize_options(self):
        self.print_flags = False
        self.compiler = None
        self.build_temp = None
        self.build_lib = None
        self.build_platlib = None
        self.build_base = "build"
        self.include_dirs = None
        self.libraries = None
        self.library_dirs = None
        self.link_objects = None
        self.debug = None
        self.optimize = 0
        self.dry_run = 0
        self.verbose = 0
        self.force = 0

    def finalize_options(self):
        self.extensions = self.distribution.ext_modules
        plat_specifier = ".%s-%s" % (get_platform(), sys.version[0:3])
        if self.build_platlib is None:
            self.build_platlib = os.path.join(self.build_base, 'lib' + plat_specifier)
        if self.build_lib is None:
            self.build_lib = self.build_platlib
        if self.build_temp is None:
            self.build_temp = os.path.join(self.build_base, 'temp' + plat_specifier)

    def run(self):
        # mostly copied from distutils.command.build_ext
        from distutils.ccompiler import new_compiler
        if not self.extensions:
            return
        self.compiler = new_compiler(
                compiler=self.compiler or patch_distutils.get_default_compiler(),
                verbose=self.verbose,
                dry_run=self.dry_run,
                force=self.force)
        from pyd import dcompiler
        assert isinstance(self.compiler, dcompiler.DCompiler)
        self.compiler.build_exe = True
        self.compiler.optimize = self.optimize
        # irrelevant for D compilers?
        #customize_compiler(self.compiler)
        if self.include_dirs is not None:
            self.compiler.set_include_dirs(self.include_dirs)
        if self.libraries is not None:
            self.compiler.set_libraries(self.libraries)
        if self.library_dirs is not None:
            self.compiler.set_library_dirs(self.library_dirs)
        if self.link_objects is not None:
            self.compiler.set_link_objects(self.link_objects)

        if self.print_flags:
            print( ' '.join(self.compiler.versionOpts()) )
        else:
            for ext in self.extensions:
                self.per_ext(ext)

    def per_ext(self, ext):
            self.compiler.init_d_opts(self, ext)
            # mostly copied from distutils.command.build_ext
            sources = ext.sources
            if sources is None or type(sources) not in (list, tuple):
                raise DistutilsSetupError(
                        ("in 'pydexe' option (extension '%s'), " +
                        "'sources' must be present and must be " +
                        "a list of source filenames") % ext.name)
            sources = list(sources)
            ext_path = self.get_ext_fullpath(ext.name)
            depends = sources + ext.depends
            if not (self.force or newer_group(depends, ext_path, 'newer')):
                log.debug("skipping '%s' extension (up-to-date)", ext.name)
                return
            else:
                log.info("building '%s' extension", ext.name)

            extra_args = ext.extra_compile_args or []
            macros = ext.define_macros[:]

            objects = self.compiler.compile(sources,
                    output_dir=self.build_temp,
                    macros=macros,
                    include_dirs=ext.include_dirs,
                    debug=self.debug,
                    extra_postargs=extra_args,
                    depends=ext.depends)
            self._built_objects = objects[:]
            if ext.extra_objects:
                objects.extend(ext.extra_objects)
            language = ext.language or self.compiler.detect_language(sources)

            self.compiler.link_executable(objects, ext_path,
                    libraries=self.get_libraries(ext),
                    library_dirs=ext.library_dirs,
                    runtime_library_dirs=ext.runtime_library_dirs,
                    extra_postargs=extra_args,
                    debug=self.debug,
                    target_lang=language)
            import shutil
            shutil.copy(self.compiler.executable_filename(ext_path), '.')

    def get_ext_fullpath(self, ext_name):
        fullname = ext_name
        modpath = fullname.split('.')
        filename = self.get_ext_filename(ext_name)
        filename = os.path.split(filename)[-1]

        filename = os.path.join(*modpath[:-1]+[filename])
        return os.path.join(self.build_lib, filename)

    def get_ext_filename(self, ext_name):
        from distutils.sysconfig import get_config_var
        ext_path = ext_name.split( ".")
        if os.name == "os2":
            old_path = ext_path[:]
            ext_path[len(ext_path)-1] = ext_path[len(ext_path)-1][:8]
            assert False, ("build_ext does this, so it probably works, but check it anyways! We are on OS2, and OS2" +
                    "does not permit file names of length > 8, so we are using %r instead of %r") % (old_path, ext_path)
        # link_executable does this for us
        # (override extension with compiler.exe_extension)
        #exe_ext = get_config_var("EXE")
        exe_ext = ''
        if os.name == "nt" and self.debug:
            return os.path.join(*ext_path) + "_d" + exe_ext
        return os.path.join(*ext_path) + exe_ext

    def get_libraries(self, ext):
        # mostly copied from build_ext.get_libraries
        if sys.platform == "win32":
            return ext.libraries
        elif sys.platform[:6] == "cygwin":
            return ext.libraries
        else:
            from distutils import sysconfig
            if sysconfig.get_config_var('Py_ENABLE_SHARED'):
                x = ''
                if hasattr(sys, 'abiflags'):
                    x = sys.abiflags
                pythonlib = "python{}.{}{}".format(
                        sys.hexversion >> 24,
                        (sys.hexversion >> 16) & 0xff,
                        x)
                if hasattr(sys,'pydebug') and sys.pydebug:
                    pythonlib += '_d'
                return ext.libraries + [pythonlib]
            else:
                return ext.libraries

def pydexe_sanity_check():
    import sys
    if sys.argv[1] != 'pydexe':
        print( "use pydexe, not %s" % sys.argv[1] )
        sys.exit(1)

def setup(*args, **kwargs):
    if 'cmdclass' not in kwargs:
        kwargs['cmdclass'] = {}
    kwargs['cmdclass']['pydexe'] = build_pyd_embedded_exe
    base_setup(*args, **kwargs)
