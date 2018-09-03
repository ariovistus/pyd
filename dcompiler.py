# DSR:2005.10.27.23.51

# XXX:
# These two will have to wait until DMD can create shared libraries on Linux,
# because DSR doesn't have (the non-free version of) MSVC 2003, which is
# necessary to create a debug build or a UCS4 build of Python 2.4 on Windows:
# - Handle distutils debug builds responsibly (make sure both -debug and -g are
#   passed through to DMD, even if optimizations are requested).  Also make
#   sure that extensions built with this module work under debug builds of
#   Python.
# - Try out a UCS4 build of Python to make sure that works.

import os, os.path, sys

from distutils import ccompiler as cc
from distutils.sysconfig import get_config_var
from distutils.ccompiler import gen_lib_options
from distutils.errors import (
    DistutilsExecError, DistutilsFileError, DistutilsPlatformError,
    CompileError, LibError, LinkError, UnknownFileError
)

_isPlatCygwin = sys.platform.lower() == 'cygwin'

def winpath(path_, winonly):
    if _isPlatCygwin and winonly:
        from subprocess import Popen, PIPE
        stdout,_ = Popen(['cygpath', '-w', path_], stdout=PIPE).communicate()
        return stdout.strip()
    else:
        return path_
def cygpath(path_, winonly):
    if _isPlatCygwin and winonly:
        from subprocess import Popen, PIPE
        stdout,_ = Popen(['cygpath', path_], stdout=PIPE).communicate()
        return stdout.strip()
    else:
        return path_

def is_posix_static_python():
    if (sys.platform == "win32" or
       sys.platform[:6] == "cygwin"):
        return False
    else:
        return not get_config_var('Py_ENABLE_SHARED')
def posix_static_python_opts():
    ls = [l for l in get_config_var('LIBS').split(' ') if l]
    print(ls)
    ls.extend([l for l in get_config_var('MODLIBS').split(' ') if l])
    print(ls)
    return ls

def posix_static_python_lib():
    return os.path.join(get_config_var('LIBPL'),get_config_var('LIBRARY'))

_isPlatWin = sys.platform.lower().startswith('win') or _isPlatCygwin
_isPlatOSX = sys.platform.lower() == 'darwin'

_infraDir = os.path.join(os.path.dirname(__file__), 'infrastructure')

from pyd.pyd_support import make_pydmain, make_pyddef

_pydFiles = [
    'class_wrap.d',
    'ctor_wrap.d',
    'def.d',
    'embedded.d',
    'exception.d',
    'extra.d',
    'func_wrap.d',
    'make_object.d',
    'make_wrapper.d',
    'op_wrap.d',
    'pyd.d',
    'pydobject.d',
    'references.d',
    'struct_wrap.d',
    'thread.d',
]

_utilFiles = [
    'conv.d',
    'typeinfo.d',
    'typelist.d',
    'multi_index.d',
    'replace.d',
]

_deimosFiles = [
    'abstract_.d',
    'ast.d',
    'boolobject.d',
    'bufferobject.d',
    'bytearrayobject.d',
    'bytesobject.d',
    'cellobject.d',
    'ceval.d',
    'classobject.d',
    'cobject.d',
    'codecs.d',
    'code.d',
    'compile.d',
    'complexobject.d',
    'cStringIO.d',
    'datetime.d',
    'descrobject.d',
    'dictobject.d',
    'enumobject.d',
    'errcode.d',
    'eval.d',
    'fileobject.d',
    'floatobject.d',
    'frameobject.d',
    'funcobject.d',
    'genobject.d',
    'grammar.d',
    'import_.d',
    'intobject.d',
    'intrcheck.d',
    'iterobject.d',
    'listobject.d',
    'longintrepr.d',
    'longobject.d',
    'marshal.d',
    'memoryobject.d',
    'methodobject.d',
    'modsupport.d',
    'moduleobject.d',
    'node.d',
    'object.d',
    'objimpl.d',
    'parsetok.d',
    'pgenheaders.d',
    'pyarena.d',
    'pyatomic.d',
    'pycapsule.d',
    'pydebug.d',
    'pyerrors.d',
    'pymem.d',
    'pyport.d',
    'pystate.d',
    'pystrcmp.d',
    'pystrtod.d',
    'Python.d',
    'pythonrun.d',
    'pythread.d',
    'rangeobject.d',
    'setobject.d',
    'sliceobject.d',
    'stringobject.d',
    'structmember.d',
    'structseq.d',
    'symtable.d',
    'sysmodule.d',
    'timefuncs.d',
    'traceback.d',
    'tupleobject.d',
    'unicodeobject.d',
    'weakrefobject.d',
]

_pyVerXDotY = '.'.join(str(v) for v in sys.version_info[:2]) # e.g., '2.4'
_pyVerXY = _pyVerXDotY.replace('.', '') # e.g., '24'

def spawn0(self, cmdElements):
    import platform
    if platform.python_version() < "2.6":
        exec(
        """
try:
    self.spawn(cmdElements)
except DistutilsExecError, msg:
    raise CompileError(msg)""")
    else:
        exec('''
try:
            self.spawn(cmdElements)
except DistutilsExecError as msg:
            raise CompileError(msg)
''')

def wrapped_spawn(self, cmdElements, tag):
    '''
    wrap spawn with unique-ish travis fold prints
    '''
    import uuid
    a = uuid.uuid1()
    print("travis_fold:start:%s-%s" % (tag, a))
    try:
        spawn0(self, cmdElements)
    finally:
        print("travis_fold:end:%s-%s" % (tag, a))


class DCompiler(cc.CCompiler):

    src_extensions = ['.d']
    obj_extension = (_isPlatWin and '.obj') or '.o'
    static_lib_extension = (_isPlatWin and '.lib') or '.a'
    shared_lib_extension = (_isPlatWin and '.pyd') or '.so'
    static_lib_format = (_isPlatWin and '%s%s') or 'lib%s%s'
    shared_lib_format = '%s%s'
    exe_extension = (_isPlatWin and '.exe') or ''

    def __init__(self, *args, **kwargs):
        cc.CCompiler.__init__(self, *args, **kwargs)
        self.winonly = False
        self.proj_name = None
        self.build_exe = False
        self.with_pyd = True
        self.with_main = True
        self.build_deimos = False
        self.lump = False
        self.optimize = False
        self.version_flags_from_ext = []
        self.debug_flags_from_ext = []
        self.string_imports_from_ext = []
        # Get DMD/GDC/LDC specific info
        self._initialize()
        # _binpath
        try:
            dBin = os.environ[self._env_var]
            if not os.path.isfile(dBin):
                self.warn("Environment variable %s provided, but file '%s' does not exist." % (self._env_var, dBin))
                raise KeyError
        except KeyError:
            if _isPlatWin:
                # The environment variable wasn't supplied, so search the PATH.
                # Windows requires the full path for reasons that escape me at
                # the moment.
                for compiler in self.executables['compiler']:
                    if '.' not in compiler:
                        compiler += self.exe_extension
                    dBin = _findInPath(compiler)
                    if dBin: break
                if dBin is None:
                    raise DistutilsFileError('You must either set the %s'
                        ' environment variable to the full path of the %s'
                        ' executable, or place the executable on the PATH.' %
                        (self._env_var, self.executables['compiler'][0])
                    )
            else:
                # Just run it via the PATH directly in Linux
                dBin = self.executables['compiler'][0]
        self._binpath = dBin
        self._unicodeOpt = 'Python_Unicode_UCS' + ((sys.maxunicode == 0xFFFF and '2') or '4')

    def _initialize(self):
        # It is intended that this method be implemented by subclasses.
        raise NotImplementedError( "Cannot initialize DCompiler, use DMDDCompiler, GDCDCompiler or LDCDCompiler instead.")

    def init_d_opts(self, cmd, ext):
            self.optimize = cmd.optimize or ext.pyd_optimize
            self.with_pyd = ext.with_pyd
            self.with_main = ext.with_main
            self.build_deimos = ext.build_deimos
            self.lump = ext.d_lump
            self.proj_name = ext.name
            self.version_flags_from_ext = ext.version_flags
            self.debug_flags_from_ext = ext.debug_flags
            self.string_imports_from_ext = ext.string_imports
            self.unittest_from_ext = ext.d_unittest
            self.property_from_ext = ext.d_property


    def _def_file(self, output_dir, output_filename):
        """A list of options used to tell the linker how to make a dll/so. In
        DMD, it is the .def file. In GDC, it is
        ['-shared', '-Wl,-soname,blah.so'] or similar."""
        raise NotImplementedError( "Cannot initialize DCompiler, use DMDDCompiler, GDCDCompiler or LDCDCompiler instead.")

    def _lib_file(self, libraries):
        return ''

    def find_library_file(self, dirs, lib, debug=0):
        shared_f = self.library_filename(lib, lib_type='shared')
        static_f = self.library_filename(lib, lib_type='static')

        for dir in dirs:
            shared = os.path.join(dir, shared_f)
            static = os.path.join(dir, static_f)

            if os.path.exists(shared):
                return shared
            elif os.path.exists(static):
                return static

        return None

    def python_versions(self):
        optf = 'Python_%d_%d_Or_Later'
        def pv2(minor):
            ret = []
            if not self.build_exe:
                ret.append('PydPythonExtension')
            ret.extend([(optf % (2,m)) for m in range(4,minor+1)])
            return ret
        def pv3(minor):
            return [(optf % (3,m)) for m in range(0,minor+1)]
        major = sys.version_info[0]
        minor = sys.version_info[1]
        if major == 2: return pv2(minor)
        if major == 3: return  pv2(7) + pv3(minor)
        assert False, "what python version is this, anyways?"

    def all_versions(self):
        return self.python_versions() + [self._unicodeOpt]

    def versionOpts(self):
        # Python version option allows extension writer to take advantage of
        # Python/C API features available only in recent version of Python with
        # a version statement like:
        #   version(Python_2_4_Or_Later) {
        #     Py_ConvenientCallOnlyAvailableInPython24AndLater();
        #   } else {
        #     // Do it the hard way...
        #   }
        return [self._versionOpt % v for v in self.all_versions()]

    def _make_object_name(self, *args):
        path = args[:-1]
        dir = os.path.join(*path)
        if not os.path.exists(dir):
            os.makedirs(dir)
        file = args[-1]+self.obj_extension
        filename = os.path.join(dir, file)
        filename = winpath(filename, self.winonly)
        filename = _qp(filename)
        return filename

    def compile(
        self, sources,
        output_dir=None, macros=None, include_dirs=None, debug=0,
        extra_preargs=None, extra_postargs=None, depends=None
    ):
        macros = macros or []
        include_dirs = include_dirs or []
        extra_preargs = extra_preargs or []
        extra_postargs = extra_postargs or []

        pythonVersionOpts = self.versionOpts()

        if not os.path.exists(output_dir):
            os.makedirs(output_dir)

        binpath = _qp(self._binpath)
        if self.build_exe:
            compileOpts = self._exeCompileOpts
        else:
            compileOpts = self._compileOpts
        outputOpts = self._outputOpts

        includePathOpts = []

        # All object files will be placed in one of three directories:
        # infra   - All of the infrastructure's object files.
        # project - The project's own object files.
        # outside - Any source files specified by the project which are not
        #           contained in the project's own directory.
        orig_sources = sources
        sources = []
        for source in orig_sources:
            if os.path.abspath(source).startswith(os.getcwd()):
                sources.append((winpath(source,self.winonly), 'project'))
            else:
                sources.append((winpath(source, self.winonly), 'outside'))

        if self.with_pyd:
            for file in _pydFiles:
                filePath = os.path.join(_infraDir, 'pyd', file)
                if not os.path.isfile(filePath):
                    raise DistutilsPlatformError("Required Pyd source file '%s' is"
                        " missing." % filePath
                    )
                sources.append((winpath(filePath,self.winonly), 'infra'))
            for file in _utilFiles:
                filePath = os.path.join(_infraDir, 'util', file)
                if not os.path.isfile(filePath):
                    raise DistutilsPlatformError("Required util source file '%s' is"
                        " missing." % filePath
                    )
                sources.append((winpath(filePath,self.winonly), 'infra'))
        if self.build_deimos:
            for file in _deimosFiles:
                filePath = os.path.join(_infraDir, 'deimos', 'python', file)
                if not os.path.isfile(filePath):
                    raise DistutilsPlatformError("Required deimos header "
                        "file '%s' is missing." % filePath
                    )
                sources.append((winpath(filePath,self.winonly), 'infra'))
        # If using PydMain, parse the template file
        if self.build_exe:
            pass
        elif self.with_main:
            name = self.proj_name
            # Store the finished pydmain.d file alongside the object files
            infra_output_dir = winpath(os.path.join(output_dir, 'infra'), self.winonly)
            if not os.path.exists(infra_output_dir):
                os.makedirs(infra_output_dir)
            mainFilename = os.path.join(infra_output_dir, 'pydmain.d')
            make_pydmain(mainFilename, name)
            sources.append((winpath(mainFilename,self.winonly), 'infra'))
        # Add the infraDir to the include path for pyd and utils.
        includePathOpts += self._includeOpts
        includePathOpts[-1] = includePathOpts[-1] % winpath(os.path.join(_infraDir), self.winonly)

        for include_dir in include_dirs:
            includePathOpts += self._includeOpts
            includePathOpts[-1] %= winpath(include_dir, self.winonly)

        if self.build_exe:
            pass
        else:
            # Add DLL/SO boilerplate code file.
            if _isPlatWin:
                boilerplatePath = os.path.join(_infraDir, 'd',
                    'python_dll_windows_boilerplate.d'
                )
            else:
                boilerplatePath = os.path.join(_infraDir, 'd',
                    'python_so_linux_boilerplate.d'
                )
            if not os.path.isfile(boilerplatePath):
                raise DistutilsFileError('Required supporting code file "%s"'
                    ' is missing.' % boilerplatePath
                )
            sources.append((winpath(boilerplatePath,self.winonly), 'infra'))

        for imp in self.string_imports_from_ext:
            if not (os.path.isfile(imp) or os.path.isdir(imp)):
                raise DistutilsFileError('String import file "%s" does not exist' %
                        imp)

        userVersionAndDebugOpts = (
              [self._versionOpt % v for v in self.version_flags_from_ext] +
              [self._debugOpt   % v for v in self.debug_flags_from_ext]
        )

        # Optimization opts
        if debug:
            optimizationOpts = self._debugOptimizeOpts
        elif self.optimize:
            optimizationOpts = self._releaseOptimizeOpts
        else:
            optimizationOpts = self._defaultOptimizeOpts

        unittestOpt = []
        if self.unittest_from_ext:
            unittestOpt.append(self._unittestOpt)
        if self.property_from_ext:
            unittestOpt.append(self._propertyOpt)
        if self.string_imports_from_ext:
            imps = set()
            for imp in self.string_imports_from_ext:
                if os.path.isfile(imp):
                    imps.add(os.path.dirname(os.path.abspath(imp)))
                else:
                    imps.add(os.path.abspath(imp))
            unittestOpt.extend([self._stringImportOpt % (imp,)
                for imp in imps])
        objFiles = []

        if self.lump:
            objName = self._make_object_name(output_dir, 'infra', 'temp')
            outOpts = outputOpts[:]
            outOpts[-1] = outOpts[-1] % objName
            cmdElements = (
                [binpath] + extra_preargs + unittestOpt + compileOpts +
                pythonVersionOpts + optimizationOpts +
                includePathOpts + outOpts + userVersionAndDebugOpts +
                [_qp(source[0]) for source in sources] + extra_postargs
            )
            cmdElements = [el for el in cmdElements if el]
            wrapped_spawn(self,cmdElements, 'pyd_compile')
            return [objName]
        else:
          for source, source_type in sources:
            outOpts = outputOpts[:]
            objFilename = os.path.splitext(source)[0]
            if source_type == 'project':
                objName = self._make_object_name(output_dir, 'project', objFilename)
            elif source_type == 'outside':
                objName = self._make_object_name(output_dir, 'outside', os.path.basename(objFilename))
            else: # infra
                objName = self._make_object_name(output_dir, 'infra', os.path.basename(objFilename))
            objFiles.append(objName)
            outOpts[-1] = outOpts[-1] % objName

            cmdElements = (
                [binpath] + extra_preargs + unittestOpt + compileOpts +
                pythonVersionOpts + optimizationOpts +
                includePathOpts + outOpts + userVersionAndDebugOpts +
                [_qp(source)] + extra_postargs
            )
            cmdElements = [el for el in cmdElements if el]
            spawn0(self,cmdElements)
        return objFiles

    def link (self,
        target_desc, objects, output_filename,
        output_dir=None,
        libraries=None, library_dirs=None, runtime_library_dirs=None,
        export_symbols=None, debug=0,
        extra_preargs=None, extra_postargs=None,
        build_temp=None, target_lang=None
    ):
        # Distutils defaults to None for "unspecified option list"; we want
        # empty lists in that case (this substitution is done here in the body
        # rather than by changing the default parameters in case distutils
        # passes None explicitly).
        libraries = libraries or []
        library_dirs = library_dirs or []
        runtime_library_dirs = runtime_library_dirs or []
        export_symbols = export_symbols or []
        extra_preargs = extra_preargs or []
        extra_postargs = extra_postargs or []

        # On 64-bit Windows we just link to pythonXX.lib from the installation
        if _is_win64(): 
            library_dirs = list(set(_build_ext_library_dirs() + library_dirs))

        binpath = self._binpath
        if hasattr(self, '_linkOutputOpts'):
            outputOpts = self._linkOutputOpts[:]
        else:
            outputOpts = self._outputOpts[:]
        objectOpts = [_qp(fn) for fn in objects]

        (objects, output_dir) = self._fix_object_args (objects, output_dir)
        (libraries, library_dirs, runtime_library_dirs) = \
            self._fix_lib_args (libraries, library_dirs, runtime_library_dirs)
        if runtime_library_dirs:
            self.warn('This CCompiler implementation does nothing with'
                ' "runtime_library_dirs": ' + str(runtime_library_dirs)
            )

        if output_dir and os.path.basename(output_filename) == output_filename:
            output_filename = os.path.join(output_dir, output_filename)
        else:
            if not output_filename:
                raise DistutilsFileError( 'Neither output_dir nor' \
                    ' output_filename was specified.')
            output_dir = os.path.dirname(output_filename)
            if not output_dir:
                raise DistutilsFileError( 'Unable to guess output_dir on the'\
                    ' bases of output_filename "%s" alone.' % output_filename)

        # Format the output filename option
        # (-offilename in DMD, -o filename in GDC, -of=filename in LDC)
        outputOpts[-1] = outputOpts[-1] % _qp(winpath(output_filename,self.winonly))

        if not os.path.exists(output_dir):
            os.makedirs(output_dir)

        if not self._need_link(objects, output_filename):
            print ("All binary output files are up to date.")
            return

        if self.build_exe:
            sharedOpts = []
            linkOpts = self._exeLinkOpts
            pythonLibOpt = []
            if target_desc != cc.CCompiler.EXECUTABLE:
                raise LinkError('This CCompiler implementation should be building'
                    ' an executable'
                )
        else:
            # The .def file (on Windows) or -shared and -soname (on Linux)
            sharedOpts = self._def_file(build_temp, output_filename)
            if target_desc != cc.CCompiler.SHARED_OBJECT:
                raise LinkError('This CCompiler implementation should be building '
                    ' a shared object'
                )
            linkOpts = self._linkOpts
        # The python .lib file, if needed
        pythonLibOpt = self._lib_file(libraries)
        if pythonLibOpt:
            pythonLibOpt = _qp(pythonLibOpt)


        # Library linkage options
        print ("library_dirs: %s" % (library_dirs,))
        print ("runtime_library_dirs: %s" % (runtime_library_dirs,))
        print ("libraries: %s"% (libraries,))
        libOpts = gen_lib_options(self, library_dirs, runtime_library_dirs, libraries)

        # Optimization opts
        if debug:
            optimizationOpts = self._debugOptimizeOpts
        elif self.optimize:
            optimizationOpts = self._releaseOptimizeOpts
        else:
            optimizationOpts = self._defaultOptimizeOpts

        cmdElements = (
            [binpath] + extra_preargs + linkOpts + optimizationOpts +
            outputOpts + [pythonLibOpt] + objectOpts + libOpts + sharedOpts +
            extra_postargs
        )
        cmdElements = [el for el in cmdElements if el]

        wrapped_spawn(self,cmdElements, 'pyd_link')

class DMDDCompiler(DCompiler):
    compiler_type = 'dmd'

    executables = {
        'preprocessor' : None,
        'compiler'     : ['dmd', 'dmd.bat'],
        'compiler_so'  : ['dmd', 'dmd.bat'],
        'linker_so'    : ['dmd', 'dmd.bat'],
        'linker_exe'   : ['dmd', 'dmd.bat'],
    }

    _env_var = 'DMD_BIN'

    def _initialize(self):
        self.winonly = True
        # _compileOpts
        self._exeCompileOpts = ['-c']
        self._compileOpts = ['-c']

        if _is_win64():
            self._exeCompileOpts.append('-m64')
            self._compileOpts.append('-m64')

        if not _isPlatWin: self._compileOpts.append('-fPIC')
        # _outputOpts
        self._outputOpts = ['-of%s']
        # _linkOpts
        if is_posix_static_python():
            self._exeLinkOpts = ['-L'+posix_static_python_lib()]
            self._exeLinkOpts.extend([
                '-L'+l for l in posix_static_python_opts()
            ])
        else:
            self._exeLinkOpts = []
        if _isPlatWin:
            self._linkOpts = []
        elif _isPlatOSX:
            self._linkOpts = ['-shared', '-L'+posix_static_python_lib()]
        else:
            self._linkOpts = ['-shared','-defaultlib=libphobos2.so']

        if _is_win64():
            self._exeLinkOpts.append('-m64')
            self._linkOpts.append('-m64')

        # _includeOpts
        self._includeOpts = ['-I%s']
        # _versionOpt
        self._versionOpt = '-version=%s'
        # _debugOpt
        self._debugOpt = '-debug=%s'
        # _defaultOptimizeOpts
        self._defaultOptimizeOpts = ['-debug']
        # _stringImportOpt
        self._stringImportOpt = '-J%s'
        # _propertyOpt
        self._propertyOpt = '-property'
        # _unittestOpt
        self._unittestOpt = '-unittest'
        # _debugOptimizeOpts
        self._debugOptimizeOpts = self._defaultOptimizeOpts + [self._unittestOpt, '-g']
        # _releaseOptimizeOpts
        self._releaseOptimizeOpts = ['-version=Optimized', '-release', '-O', '-inline']

    #def link_opts(self,

    def _def_file(self, output_dir, output_filename):
        if _isPlatWin:
            # Automatically create a .def file:
            defFilePath = os.path.join(output_dir, 'infra', 'python_dll_def.def')
            make_pyddef(
                defFilePath,
                os.path.basename(output_filename)
            )
            return [winpath(defFilePath,self.winonly)]
        else:
            return []

    def _lib_file(self, libraries):

        if _isPlatWin and not _is_win64():
            # The DMD-compatible .lib file can be generated with implib.exe
            # (from the Digital Mars "Basic Utilities" package) using a command
            # series similar to the following:
            #   cd C:\Windows\system32
            #   \path\to\dm\bin\implib.exe /system python24_digitalmars.lib python24.dll
            #
            # I chose not to incorporate automatic .lib generation into this
            # code because Python X.Y releases are fairly infrequent, so it's
            # more convenient to distribute a pre-extracted .lib file to the
            # users and spare them the need for the "Basic Utilities" package.
            pythonDMDLibPath = _qp(os.path.join(_infraDir, 'windows',
                'python%s_digitalmars.lib' % _pyVerXY
            ))
            if not os.path.isfile(pythonDMDLibPath):
                raise DistutilsFileError('The DMD-compatible Python .lib file'
                    ' which should be located at "%s" is missing.  Try'
                    ' downloading a more recent version of celeriD that'
                    ' contains a .lib file appropriate for your Python version.'
                    % pythonDMDLibPath
                )
            pythonLibOpt = _qp(winpath(pythonDMDLibPath,self.winonly))

            # distutils will normally request that the library 'pythonXY' be
            # linked against.  Since D requires a different .lib file from the
            # one used by the C compiler that built Python, and we've just
            # dealt with that requirement, we take the liberty of removing the
            # distutils-requested pythonXY.lib.
            if 'python' + _pyVerXY in libraries:
                libraries.remove('python' + _pyVerXY)
            if False and _isPlatCygwin and 'python' + _pyVerXDotY  in libraries:
                libraries.remove('python' + _pyVerXDotY)
            return pythonLibOpt
        else:
            return ''

    def library_dir_option(self, dir):
        if _is_win64():
            return r'-L/LIBPATH:\"' + dir + r'\"'
        else:
            return '-L-L' + dir

    def runtime_library_dir_option(self, dir):
        if not _isPlatWin:
            return '-L-R' + dir
        else:
            self.warn("Don't know how to set runtime library search path for DMD on Windows.")

    def library_option(self, lib):
        if _isPlatWin:
            return self.library_filename(lib)
        else:
            return '-L-l' + lib
    def compile(self, *args, **kwargs):
        if not _isPlatWin and not self.build_exe:
            output_dir = kwargs.get('output_dir', '')
            if not os.path.exists(os.path.join(output_dir,'infra')):
                os.makedirs(os.path.join(output_dir,'infra'))
            src = os.path.join(_infraDir, 'd', 'so_ctor.c')
            dsto = os.path.join(output_dir, 'infra', 'so_ctor.o')
            spawn0(self,['gcc','-c', src, '-fPIC','-o',dsto])
            self._dmd_so_ctor = dsto
        return DCompiler.compile(self, *args, **kwargs)
    def link (self, *args, **kwargs):
        if not _isPlatWin and not self.build_exe:
            args[1].append(self._dmd_so_ctor)
        return DCompiler.link(self, *args, **kwargs)

class GDCDCompiler(DCompiler):
    compiler_type = 'gdc'

    executables = {
        'preprocessor' : None,
        'compiler'     : ['gdc'],
        'compiler_so'  : ['gdc'],
        'linker_so'    : ['gdc'],
        'linker_exe'   : ['gdc'],
    }

    _env_var = 'GDC_BIN'

    def _initialize(self):
        self._exeCompileOpts = ['-c']
        # _compileOpts
        self._compileOpts = ['-fPIC', '-c']
        # _outputOpts
        self._outputOpts = ['-o', '%s']
        if is_posix_static_python():
            self._exeLinkOpts = posix_static_python_opts()
            self._exeLinkOpts.append(posix_static_python_lib())
        else:
            self._exeLinkOpts = []
        # _linkOpts
        self._linkOpts = ['-fPIC', '-shared', '-lgdruntime', '-lgphobos']
        # _includeOpts
        self._includeOpts = ['-I', '%s']
        # _versionOpt
        self._versionOpt = '-fversion=%s'
        # _debugOpt
        self._debugOpt = '-fdebug=%s'
        # _defaultOptimizeOpts
        self._defaultOptimizeOpts = ['-fdebug']
        # _stringImportOpt
        self._stringImportOpt = '-J%s'
        # _propertyOpt
        self._propertyOpt = '-fproperty'
        # _unittestOpt
        self._unittestOpt = '-funittest'
        # _debugOptimizeOpts
        self._debugOptimizeOpts = self._defaultOptimizeOpts + ['-g', self._unittestOpt]
        # _releaseOptimizeOpts
        self._releaseOptimizeOpts = ['-fversion=Optimized', '-frelease', '-O3']

    def compile(self, *args, **kwargs):
        if not _isPlatWin and not self.build_exe:
            output_dir = kwargs.get('output_dir', '')
            if not os.path.exists(os.path.join(output_dir,'infra')):
                os.makedirs(os.path.join(output_dir,'infra'))
            src = os.path.join(_infraDir, 'd', 'so_ctor.c')
            dsto = os.path.join(output_dir, 'infra', 'so_ctor.o')
            spawn0(self,['gcc','-c', src, '-fPIC','-o',dsto])
            self._gdc_so_ctor = dsto
        return DCompiler.compile(self, *args, **kwargs)

    def link (self, *args, **kwargs):
        if not _isPlatWin and not self.build_exe:
            args[1].append(self._gdc_so_ctor)
        return DCompiler.link(self, *args, **kwargs)

    def _def_file(self, output_dir, output_filename):
        return ['-Wl,-soname,' + os.path.basename(output_filename)]

    def library_dir_option(self, dir):
        return '-L' + dir

    def runtime_library_dir_option(self, dir):
        return '-Wl,-R' + dir

    def library_option(self, lib):
        return '-l' + lib

class LDCDCompiler(DCompiler):
    compiler_type = 'ldc'
    linker_type = 'gcc'

    executables = {
        'preprocessor' : None,
        'compiler'     : ['ldc2'],
        'compiler_so'  : ['ldc2'],
        'linker_so'    : ['ldc2'],
        'linker_exe'   : ['ldc2'],
    }

    # this is not a env! (but it isn't GDC)
    _env_var = 'LDC_BIN'

    def _initialize(self):
        self._exeCompileOpts = ['-c']
        # _compileOpts
        self._compileOpts = ['-relocation-model=pic', '-c']
        # _outputOpts
        self._outputOpts = ['-of', '%s']
        self._linkOutputOpts = ['-of', '%s']
        # bloody ubuntu has to make things difficult
        if is_posix_static_python():
            self._exeLinkOpts = ['-L'+l for l in posix_static_python_opts()]
            self._exeLinkOpts.append(posix_static_python_lib())
        else:
            self._exeLinkOpts = []
        # _linkOpts
        self._SharedLinkOpts = ['-shared']
        if _isPlatOSX:
            self._SharedLinkOpts.append('-L'+posix_static_python_lib())
        # _includeOpts
        self._includeOpts = ['-I', '%s']
        # _versionOpt
        self._versionOpt = '-d-version=%s'
        # _debugOpt
        self._debugOpt = '-d-debug=%s'
        # _defaultOptimizeOpts
        self._defaultOptimizeOpts = ['-d-debug']
        # _stringImportOpt
        self._stringImportOpt = '-J=%s'
        # _propertyOpt
        self._propertyOpt = '-property'
        # _unittestOpt
        self._unittestOpt = '-unittest'
        # _debugOptimizeOpts
        self._debugOptimizeOpts = self._defaultOptimizeOpts + ['-g', self._unittestOpt]
        # _releaseOptimizeOpts
        self._releaseOptimizeOpts = ['-d-version=Optimized', '-release', '-O3']

    def init_d_opts(self, cmd, ext):
        DCompiler.init_d_opts(self,cmd, ext)
        if self.lump:
            if self.build_exe and '-singleobj' not in self._exeCompileOpts:
                self._exeCompileOpts.append('-singleobj')
            elif not self.build_exe and '-singleobj' not in self._compileOpts:
                self._compileOpts.append('-singleobj')
    def _def_file(self, output_dir, output_filename):
        return []

    def library_dir_option(self, dir):
        return "-L-L" + dir

    def runtime_library_dir_option(self, dir):
        return '-Wl,-R' + dir

    def library_option(self, lib):
        return "-L-l" + lib
    def link (self, *args, **kwargs):
        target_desc = args[0]
        if target_desc == cc.CCompiler.SHARED_OBJECT:
            self._binpath = self.executables['linker_so'][0]
            self._linkOpts = self._SharedLinkOpts
        elif target_desc == cc.CCompiler.EXECUTABLE:
            self._binpath = self.executables['linker_exe'][0]
            self._linkOpts = self._exeLinkOpts
            self._linkOutputOpts = self._outputOpts
        else:
            raise LinkError('This CCompiler implementation does not know'
                ' how to link anything except an extension module (that is, a'
                ' shared object file).'
            )
        return DCompiler.link(self, *args, **kwargs)


# Utility functions:
def _findInPath(fileName, startIn=None):
    # Find a file named fileName in the PATH, starting in startIn.
    try:
        path = os.environ['PATH']
    except KeyError:
        pass
    else:
        pathDirs = path.split(os.pathsep)
        if startIn:
            if startIn in pathDirs:
                pathDirs.remove(startIn)
            pathDirs.insert(0, startIn)

        for pd in pathDirs:
            tentativePath = os.path.join(pd, fileName)
            if os.path.isfile(tentativePath):
                return tentativePath

    return None


def _qp(path): # Originally: If path contains any whitespace, quote it.
    # Actually paths with spaces will be quoted again later
    # so if we do it here, there will be extra quotes like
    # ""C:\Program Files\..."" and the build will fail
    # So, don't do it here.
    return path

def _is_win64():
    import platform
    return _isPlatWin and platform.architecture()[0] == '64bit'


def _build_ext_library_dirs():
    # _setup_distribution is private but I don't know of any other way to get
    # the already built-up library_dirs so as to be able to link to the
    # python library
    from distutils.core import _setup_distribution as dist
    build_ext = dist.get_command_obj('build_ext')
    return build_ext.library_dirs
