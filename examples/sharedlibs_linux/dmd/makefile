# ###########################################################
#DMD=dmd
DMD=dmd -m32 
GCC=gcc -m32
#DMD=dmd -m32 -v
test1: test1.x libtest1.so
	LD_LIBRARY_PATH=. ./test1.x
clean:
	rm -f *.o
	rm -f *.so
	rm -f *.x

test1.o: test1.d
	$(DMD) -fPIC -shared -c $^ -of$@
libtest1.so: test1.o
	$(GCC) -nostartfiles $< -shared -o $@ -L/usr/lib64/dmd-2.060 -L/usr/lib/dmd-2.060 -Xlinker --no-warn-search-mismatch -Xlinker --export-dynamic -lphobos2 -lpthread -lm -lrt

test1.x: test1.c libtest1.so
	LD_LIBRARY_PATH=. $(GCC) $< -L. -ltest1 -o $@

# ###########################################################
