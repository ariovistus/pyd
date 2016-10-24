all:
	dmd libdir1/foo.d -fPIC -lib -oflibdir1/liblib1
	dmd libdir2/bar.d -fPIC -lib -oflibdir2/liblib2
	python setup.py build --compiler=dmd

clean:
	rm -rf build
	rm libdir1/liblib1.*
	rm libdir2/liblib2.*
