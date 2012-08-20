x.so: xclass.c
	python setup.py build
	cp build/lib.linux-x86_64-2.7/x.so x.so
	rm -rf build 

clean:
	rm -rf build
	rm -f x.so
