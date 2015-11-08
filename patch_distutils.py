# The distutils.ccompiler module doesn't allow the runtime addition of compiler
# classes that live outside the distutils package, and of course it doesn't
# recognize the D language and its associated compilers by default.
#
# This module hot-patches distutils.ccompiler to overcome those limitations.
#
# To apply these changes, the setup.py file for extension modules written in D
# should execute the following import statement:
#   from pyd import patch_distutils

from distutils import ccompiler as cc
from distutils.command import build, build_ext

from pyd import dcompiler

cc.CCompiler.language_map['.d'] = 'd'
cc.CCompiler.language_order.insert(0, 'd')

d_compilers = {
    'dmd': ('pyd.dcompiler', 'DMDDCompiler', 'Digital Mars D'),
    'gdc': ('pyd.dcompiler', 'GDCDCompiler', 'GCC D Compiler'),
    'ldc': ('pyd.dcompiler', 'LDCDCompiler', 'LLVM D Compiler'),
    'ldc2': ('pyd.dcompiler', 'LDCDCompiler', 'LLVM D Compiler'),
}

for compiler, compiler_class in d_compilers.items():
    cc.compiler_class[compiler] = compiler_class

_old_new_compiler = cc.new_compiler

def new_compiler(compiler=None, dry_run=0, force=0, **kwargs):
    if compiler is not None:
        compiler = compiler.lower()

    if compiler not in d_compilers:
        return _old_new_compiler(compiler=compiler,
            dry_run=dry_run, force=force, **kwargs
          )
    else:
        # non-lazy people should probably use import_module here
        DCompiler = getattr(dcompiler, d_compilers[compiler][1])
        return DCompiler(None, dry_run, force)

cc.new_compiler = new_compiler
#   python setup.py build --compiler=dmd
def get_default_compiler(*args, **kwargs):
    if dcompiler._isPlatWin:
        return 'dmd'
    else:
        return 'dmd'
# Force the distutils build command to recognize the '--optimize' or '-O'
# command-line option.
build.build.user_options.extend(
    [('optimize', 'O',
      'Ask the D compiler to optimize the generated code, at the expense of'
      ' safety features such as array bounds checks.'), ])
build.build.boolean_options.append('optimize')

_old_initialize_options = build.build.initialize_options
def _new_initialize_options(self):
    _old_initialize_options(self)
    self.optimize = 0
build.build.initialize_options = _new_initialize_options

# Force build commands to actually send optimize option to D compilers

_old_build_ext = build_ext.build_ext.build_extension

def reinit_compiler(ext):
    # build_ext.run initializes compiler then calls build_extensions.
    # we don't want that last part..
    old_build_exts = ext.build_extensions
    ext.compiler = None
    def durp(): pass
    ext.build_extensions = durp
    ext.build_extensions()
    try:
        ext.run()
    finally:
        ext.build_extensions = old_build_exts

def new_build_ext(self, ext):
    old_compiler = None
    lang = ext.language or self.compiler.detect_language(ext.sources)
    # we handle d default compiler here now
    if lang == 'd' and not isinstance(self.compiler, dcompiler.DCompiler):
        self.compiler = new_compiler('dmd')
    if lang != 'd' and isinstance(self.compiler, dcompiler.DCompiler):
        # probably user put --compiler=somedcompiler in the command line.
        # welp, lets try to rerun the compiler initializer for this extension
        old_compiler = self.compiler
        reinit_compiler(self)
    if isinstance(self.compiler, dcompiler.DCompiler):
        build = self.distribution.get_command_obj('build')
        self.compiler.init_d_opts(build, ext)
    _old_build_ext(self,ext)
    if old_compiler:
        self.compiler = old_compiler
build_ext.build_ext.build_extension = new_build_ext
