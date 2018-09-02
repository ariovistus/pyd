import sys
import os
import os.path
import shutil
import subprocess
import platform
import nose
from unittest import TestCase
from nose.plugins import Plugin
from nose.tools import with_setup
from distutils.sysconfig import get_config_var

if platform.python_version() < "2.5":
    def check_call(*args, **kwargs):
        ret = subprocess.call(*args, **kwargs)
        if ret != 0:
            cmd = kwargs.get('args', args[0])
            raise Exception("command '%s' returned %s" % (cmd, ret))
    subprocess.check_call = check_call

here = os.getcwd()
exe_ext = get_config_var("EXE")

compiler = None
debug = False
do_clean = False


def pybuild():
    pybuild_cmds = [sys.executable, "setup.py", "build"]
    if compiler is not None:
        pybuild_cmds.append("--compiler="+compiler)
    subprocess.check_call(pybuild_cmds)


class OurPlugin(Plugin):
    def options(self, parser, env=os.environ):
        parser.add_option("--compiler", dest="compiler")
        parser.add_option("--clean", action="store_true", dest="clean")
        parser.add_option('--d-debug', action="store_true", dest="debug")

    def configure(self, options, conf):
        global do_clean, compiler, debug
        debug = options.debug

        if options.compiler:
            compiler = options.compiler
        if options.clean:
            do_clean = True


def setup():
    os.chdir(here)


def teardown():
    pass


def build_and_run():
    if do_clean:
        if os.path.exists("build"):
            shutil.rmtree("build")
        return
    pybuild()
    subprocess.check_call([sys.executable, "test.py"])


@with_setup(setup, teardown)
def test_compare_offsets():
    os.chdir("tests")
    os.chdir("compare_offsets")
    build_and_run()

@with_setup(setup, teardown)
def test_hello():
    os.chdir("examples")
    os.chdir("hello")
    build_and_run()


@with_setup(setup, teardown)
def test_many_libs():
    os.chdir("tests")
    os.chdir("many_libs")
    build_and_run()


@with_setup(setup, teardown)
def test_arraytest():
    os.chdir("examples")
    os.chdir("arraytest")
    build_and_run()


@with_setup(setup, teardown)
def test_inherit():
    os.chdir("examples")
    os.chdir("inherit")
    build_and_run()


@with_setup(setup, teardown)
def test_rawexample():
    os.chdir("examples")
    os.chdir("rawexample")
    build_and_run()


@with_setup(setup, teardown)
def test_testdll():
    os.chdir("examples")
    os.chdir("testdll")
    build_and_run()


@with_setup(setup, teardown)
def test_d_and_c():
    os.chdir("examples")
    os.chdir("misc")
    os.chdir("d_and_c")
    build_and_run()


@with_setup(setup, teardown)
def test_multithreading():
    os.chdir("tests")
    os.chdir("multithreading")
    build_and_run()


def build_pydexe():
    cmds = [sys.executable, "setup.py", "pydexe"]
    if compiler is not None:
        cmds.append("--compiler="+compiler)
    if debug:
        cmds.append("-g")
    subprocess.check_call(cmds)


def remove_exe(cmd):
    if os.path.exists(cmd + exe_ext):
        os.remove(cmd+exe_ext)


def build_and_run_pydexe(nom):
    if do_clean:
        if os.path.exists("build"):
            shutil.rmtree("build")
        remove_exe(nom)
        return
    build_pydexe()
    subprocess.check_call([os.path.join(".", nom + exe_ext)])


@with_setup(setup, teardown)
def test_extra():
    os.chdir("tests")
    os.chdir("pyd_unittests")
    os.chdir("extra")
    build_and_run_pydexe("extra")


class ErrorTests(TestCase):
    def setUp(self):
        setup();
        os.chdir("tests")
        os.chdir("errors")

    def test_error1(self):
        os.chdir("error1")
        if do_clean:
            if os.path.exists("build"):
                shutil.rmtree("build")
            return
        pybuild_cmds = [sys.executable, "setup.py", "build"]
        if compiler is not None:
            pybuild_cmds.append("--compiler="+compiler)
        proc = subprocess.Popen(pybuild_cmds, stderr=subprocess.PIPE)
        stdout, stderr = proc.communicate()
        stderr = stderr.decode('utf-8')
        assert "Test: Cannot find constructor with params (int) among" in stderr 
        assert "Test(immutable(int))" in stderr 

class PydUnittests(TestCase):
    def setUp(self):
        setup()
        os.chdir("tests")
        os.chdir("pyd_unittests")

    def tearDown(self):
        teardown()

    def test_class_wrap(self):
        os.chdir("class_wrap")
        build_and_run_pydexe("class_wrap")

    def test_def(self):
        os.chdir("def")
        build_and_run_pydexe("def")

    def test_embedded(self):
        os.chdir("embedded")
        build_and_run_pydexe("embedded")

    def test_make_object(self):
        os.chdir("make_object")
        build_and_run_pydexe("make_object")

    def test_pydobject(self):
        os.chdir("pydobject")
        build_and_run_pydexe("pydobject")

    def test_struct_wrap(self):
        os.chdir("struct_wrap")
        build_and_run_pydexe("struct_wrap")

    def test_const(self):
        os.chdir("const")
        build_and_run_pydexe("const")

    def test_typeinfo(self):
        os.chdir("typeinfo")
        build_and_run_pydexe("typeinfo")

    def test_func_wrap(self):
        os.chdir("func_wrap")
        build_and_run_pydexe("func_wrap")

    def test_thread(self):
        os.chdir("thread")
        build_and_run_pydexe("thread")


class DeimosUnittests(TestCase):
    def setUp(self):
        setup()
        os.chdir("tests")
        os.chdir("deimos_unittests")

    def tearDown(self):
        teardown()

    def test_link(self):
        os.chdir('link')
        build_and_run_pydexe("link")

    def test_object(self):
        os.chdir('object_')
        build_and_run_pydexe("object_")

    def test_datetime(self):
        os.chdir('datetime')
        build_and_run_pydexe("datetime")


@with_setup(setup, teardown)
def test_pyind():
    os.chdir('examples')
    os.chdir('pyind')
    build_and_run_pydexe("pyind")


@with_setup(setup, teardown)
def test_simple_embedded():
    os.chdir('examples')
    os.chdir('simple_embedded')
    build_and_run_pydexe("hello")


@with_setup(setup, teardown)
def test_interpcontext():
    os.chdir('examples')
    os.chdir('interpcontext')
    build_and_run_pydexe("interpcontext")


@with_setup(setup, teardown)
def test_def():
    os.chdir('examples')
    os.chdir('def')
    build_and_run()


@with_setup(setup, teardown)
def test_pydobject():
    os.chdir('examples')
    os.chdir('pydobject')
    build_and_run_pydexe("example")


nose.main(addplugins=[OurPlugin()])
