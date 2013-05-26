# The distutils.ccompiler module doesn't allow the runtime addition of compiler
# classes that live outside the distutils package, and of course it doesn't
# recognize the D language and its associated compilers by default.
#
# This module hot-patches distutils.ccompiler to overcome those limitations.
#
# To apply these changes, the setup.py file for extension modules written in D
# should execute the following import statement:
#   from celerid import patch_distutils

from distutils import ccompiler as cc
from distutils.command import build, build_ext

from celerid import dcompiler

cc.CCompiler.language_map['.d'] = 'd'
cc.CCompiler.language_order.insert(0, 'd')

cc.compiler_class['dmd'] = ('celerid.dcompiler', 'DMDDCompiler', 'Digital Mars D')
cc.compiler_class['gdc'] = ('celerid.dcompiler', 'GDCDCompiler', 'GCC D Compiler')
cc.compiler_class['ldc'] = ('celerid.dcompiler', 'LDCDCompiler', 'LLVM D Compiler')

_old_new_compiler = cc.new_compiler

def new_compiler(compiler=None, dry_run=0, force=0, **kwargs):
    if compiler is not None:
        compiler = compiler.lower()

    if compiler is None:
        if dcompiler._isPlatWin:
            compiler = 'dmd'
        else:
            compiler = 'dmd'

    if compiler not in ('dmd', 'gdc','ldc'):
        return _old_new_compiler(compiler=compiler,
            dry_run=dry_run, force=force, **kwargs
          )
    elif compiler == 'dmd':
        return dcompiler.DMDDCompiler(None, dry_run, force)
    elif compiler == 'ldc':
        return dcompiler.LDCDCompiler(None, dry_run, force)
    elif compiler == 'gdc':
        return dcompiler.GDCDCompiler(None, dry_run, force)
    else:
        raise RuntimeError("Couldn't get a compiler...")

cc.new_compiler = new_compiler


# A user's setup.py wouldn't have imported this module unless it intended to
# compile D code, so override the default compiler setting to point to DMD.
# This allows a user to compile a D extension with the command line
#   python setup.py build
# instead of needing
#   python setup.py build --compiler=dmd
def get_default_compiler(*args, **kwargs):
    if dcompiler._isPlatWin:
        return 'dmd'
    else:
        return 'dmd'

cc.get_default_compiler = get_default_compiler

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

def new_build_ext(self, ext):
    if isinstance(self.compiler, dcompiler.DCompiler):
        build = self.distribution.get_command_obj('build')
        self.compiler.init_d_opts(build, ext)
    _old_build_ext(self,ext)
build_ext.build_ext.build_extension = new_build_ext
