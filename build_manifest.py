import os, os.path
import itertools
import sys
import re


FORBIDDEN_EXTENSIONS = [
    '.pyc', '.pyo', # Python bytecode
    '.marks', # jEdit bookmark files
    '.map', # Created automatically by the DMD compiler; needn't distribute.
    '.swp', # Vim swap files
  ]

FORBIDDEN_DIRECTORIES = [
    lambda d: d.lower() in ('.svn', 'cvs', 'build', 'dist', '.hg', '.git', '.tup'),
    lambda d: d.startswith('__'),
  ]

INCLUDE_ONLY_IN_SOURCE_DISTRIBUTION = [
    'build_manifest.py',
    'setup.py',
  ]

def split_complete(path):
    folders = []
    while True:
        path, p2 = os.path.split(path)
        if p2 != '':
            folders.append(p2)
        else:
            if path!='':
                folders.append(path)
            break
    return list(reversed(folders))
def include_path(path):
    pathsubs = split_complete(path)
    assert pathsubs
    filebase, ext = os.path.splitext(pathsubs[-1])
    if pathsubs[0] == 'infrastructure':
        if pathsubs == ['infrastructure','pyd','LICENSE']:
            return True
        if pathsubs == ['infrastructure','d','python_dll_def.def_template']:
            return True
        if pathsubs == ['infrastructure','d','so_ctor.c']:
            return True
        if pathsubs == ['infrastructure','python','python.d']:
            return False
        if ext.lower() == '.d':
            return True
        if pathsubs[0:2] == ['infrastructure','windows'] and \
                re.match("python.._digitalmars\\.lib",pathsubs[-1]):
            return True
        return False
    if len(pathsubs) == 1 and ext.lower() == '.py':
        return True
    if len(pathsubs) == 1 and pathsubs[0] == "version.txt":
        return True
    return False


def buildManifest(outputStream, isForSourceDist):
    includedPaths, excludedPaths = listFiles(isForSourceDist)
    for path in includedPaths:
        # print >> outputStream, 'include "%s"' % convertPathToDistutilsStandard(path)
        outputStream.write(convertPathToDistutilsStandard(path))
        outputStream.write("\n")


def convertPathToDistutilsStandard(path):
    return path.replace(os.sep, '/')


def listFiles(isForSourceDist):
    curDirAndSep = os.curdir + os.sep

    includedPaths = []
    excludedPaths = []
    for rootPath, dirs, files in os.walk(os.curdir):
        if rootPath.startswith(os.curdir + os.sep):
            rootPath = rootPath[len(os.curdir + os.sep):]
        elif rootPath.startswith(os.curdir):
            rootPath = rootPath[len(os.curdir):]

        # The os.walk interface specifies that destructively modifying dirs
        # will influence which subdirs are visited, so we determine which
        # subdirs are forbidden and remove them from dirs.
        for subDir in dirs[:]:
            for filterFunc in FORBIDDEN_DIRECTORIES:
                if filterFunc(subDir):
                    dirs.remove(subDir)

        for f in sorted(files):
            fPath = os.path.join(rootPath, f)
            if os.path.splitext(f)[1].lower() in FORBIDDEN_EXTENSIONS:
                excludedPaths.append(fPath)
            else:
                includedPaths.append(fPath)

    if not isForSourceDist:
        for path in INCLUDE_ONLY_IN_SOURCE_DISTRIBUTION:
            if path in includedPaths:
                includedPaths.remove(path)
                excludedPaths.append(path)

    excludedPaths.extend([path for path in includedPaths if not include_path(path)])
    includedPaths = [path for path in includedPaths if include_path(path)]

    return includedPaths, excludedPaths


if __name__ == '__main__':
    import sys
    buildManifest(sys.stdout, True)
