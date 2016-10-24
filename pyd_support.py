from distutils.errors import DistutilsPlatformError
import sys
from pyd.dcompiler import _infraDir
import os.path

def make_pydmain(outputFile, projname):
    mainTemplatePath = os.path.join(_infraDir, 'd', 'pydmain_template.d')
    if not os.path.isfile(mainTemplatePath):
        raise DistutilsPlatformError(
            "Required supporting code file %s is missing." % mainTemplatePath
        )
    mainTemplate = open(mainTemplatePath).read()
    mainFileContent = mainTemplate % {'modulename' : projname}
    mainFile = open(outputFile, 'w')
    mainFile.write(mainFileContent)
    mainFile.close()

def make_pyddef(outputFile, projname):
    defTemplatePath = os.path.join(_infraDir, 'd',
        'python_dll_def.def_template'
    )
    if not os.path.isfile(defTemplatePath):
        raise DistutilsFileError('Required def template file "%s" is'
            ' missing.' % defTemplatePath
        )
    f = open(defTemplatePath)
    try:
        defTemplate = f.read()
    finally:
        f.close()
    defFileContent = defTemplate % projname
    f = open(outputFile, 'w')
    try:
        f.write(defFileContent)
    finally:
        f.close()

if __name__ == '__main__':
    make_pydmain(sys.argv[2], sys.argv[1])
    make_pyddef(sys.argv[3], sys.argv[1])

