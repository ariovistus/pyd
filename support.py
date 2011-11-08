__all__ = ('setup', 'Extension')

from celerid import patch_distutils # Cause distutils to be hot-patched.

from distutils.core import setup, Extension as std_Extension
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
        define_macros = []
        if 'version_flags' in kwargs or 'debug_flags' in kwargs:
            if 'version_flags' in kwargs:
                for flag in kwargs['version_flags']:
                    define_macros.append((flag, 'version'))
                del kwargs['version_flags']

            if 'debug_flags' in kwargs:
                for flag in kwargs['debug_flags']:
                    define_macros.append((flag, 'debug'))
                del kwargs['debug_flags']

        # Pass in the extension name so the compiler class can know it
        if 'name' in kwargs:
            define_macros.append((kwargs['name'], 'name'))
        elif len(args) > 0:
            define_macros.append((args[0], 'name'))

        # Pass in the 'tango' flag, also
        with_tango = kwargs.pop('tango', False)
        if with_tango:
            define_macros.append(('Pyd_with_Tango', 'version'))
        kwargs['define_macros'] = define_macros

        # Similarly, pass in with_pyd, &c, via define_macros.
        if 'raw_only' in kwargs:
            kwargs['with_pyd'] = False
            kwargs['with_st'] = False
            kwargs['with_meta'] = False
            kwargs['with_main'] = False
            del kwargs['raw_only']
        with_pyd  = kwargs.pop('with_pyd', True)
        with_st   = kwargs.pop('with_st', False) # 5/23/07 st off by default.
        # StackThreads doesn't work with Tango at the moment.
        if with_tango:
            with_st = False
        with_meta = kwargs.pop('with_meta', True)
        with_main = kwargs.pop('with_main', True)
        if with_pyd and not with_meta:
            raise DistutilsOptionError(
                'Cannot specify with_meta=False while using Pyd. Specify'
                ' raw_only=True or with_pyd=False if you want to compile a raw Python/C'
                ' extension.'
            )
        if with_main and not with_pyd:
            # The special PydMain function should only be used when using Pyd
            with_main = False

        define_macros.append(((with_pyd, with_st, with_meta, with_main), 'aux'))

        std_Extension.__init__(self, *args, **kwargs)

