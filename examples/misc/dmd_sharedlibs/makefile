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

libtest1.so: test1.d test1helper.c
	$(GCC) -c test1helper.c -o test1helper.o
	$(DMD) -fPIC -shared $< test1helper.o -of$@

test1.x: test1.c libtest1.so
	LD_LIBRARY_PATH=. $(GCC) $< -L. -ltest1 -o $@

# ###########################################################
