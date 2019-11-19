from distutils import sysconfig
import os

python_version = sysconfig.get_config_var('VERSION')
python_version_compact = python_version.replace('.', '')

if python_version_compact[0] == '2':
	versionNumbers = list(map(lambda n: '2_' + str(n),
		range(4, int(python_version_compact[1]) + 1)))
else:
	versionNumbers = list(map(lambda n: '2_' + str(n),
		range(4, 8)))
	versionNumbers += list(map(lambda n: '3_' + str(n),
		range(0, int(python_version_compact[1]) + 1)))

if os.name == 'nt':
	set_prefix = 'set'
else:
    set_prefix = 'export'

for i in range(13):
	if i < len(versionNumbers):
		v = "Python_{}_Or_Later".format(versionNumbers[i])
	else:
		v = "__PYD__DUMMY__"
	print("{} PYD_D_VERSION_{}={}".format(set_prefix, i + 1, v))

if os.name == 'nt':
	library_path = os.path.join(sysconfig.get_config_var('BINDIR'), "libs")
	libname = "python" + python_version_compact
else:
	library_path = sysconfig.get_config_var('LIBDIR')
	libname = "python" + (sysconfig.get_config_var('LDVERSION') or python_version)

print("{} PYD_LIBPYTHON_DIR={}".format(set_prefix, library_path))
print("{} PYD_LIBPYTHON={}".format(set_prefix, libname))
