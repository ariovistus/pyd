import os, os.path


FORBIDDEN_EXTENSIONS = [
    '.pyc', '.pyo', # Python bytecode
    '.marks', # jEdit bookmark files
    '.map', # Created automatically by the DMD compiler; needn't distribute.
    '.swp', # Vim swap files
  ]

FORBIDDEN_DIRECTORIES = [
    lambda d: d.lower() in ('.svn', 'cvs', 'build', 'dist'),
    lambda d: d.startswith('__'),
  ]

INCLUDE_ONLY_IN_SOURCE_DISTRIBUTION = [
    'build_manifest.py',
    'setup.py',
  ]

EXCLUDE_PATHS = [
    'MANIFEST',
  ]


def buildManifest(outputStream, isForSourceDist):
    includedPaths, excludedPaths = listFiles(isForSourceDist)
    for path in includedPaths:
        # print >> outputStream, 'include "%s"' % convertPathToDistutilsStandard(path)
        print >> outputStream, convertPathToDistutilsStandard(path)


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

    for path in EXCLUDE_PATHS:
        if path in includedPaths:
            includedPaths.remove(path)
            excludedPaths.append(path)

    return includedPaths, excludedPaths


if __name__ == '__main__':
    import sys
    buildManifest(sys.stdout, True)
