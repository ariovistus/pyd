# ###########################################################
# from fedora repos
LDC=ldc2

# build a shared library written in D, main program written in C.
test1: test1.x libtest1.so
	LD_LIBRARY_PATH=. ./test1.x

# build 2 shared libraries written in D, main program written in C.
# not working: druntime needs some tlc.
test2: test2.x libtest2a.so libtest2b.so
	LD_LIBRARY_PATH=. ./test2.x
# build a shared library written in C with global data. Access global data in D
test3: test3.x libtest3.so
	LD_LIBRARY_PATH=. ./test3.x
clean:
	rm -f *.o
	rm -f *.so
	rm -f *.x

LIBS= -Wl,--no-as-needed -lphobos-ldc -ldruntime-ldc -lrt -lpthread -ldl -lm -lpython2.7

%.o: %.d
	echo "building $@"
	$(LDC) -relocation-model=pic -c $^ -of $@

lib%.so: %.o
	echo "building $@"
	gcc -nostartfiles -shared $(LIBS) $^ -o $@ 

test1.x: test1.c libtest1.so
	echo "building $@"
	gcc $< -l:libtest1.so -o $@ 

test2.x: test2.c libtest2a.so libtest2b.so
	echo "building $@"
	LD_LIBRARY_PATH=. gcc $< -L. -ltest2a -ltest2b -o $@

test3.x: test3.d libtest3.so
	LD_LIBRARY_PATH=. $(LDC) $< -L-L. -L-ltest3 -of $@ 
libtest3.so: test3lib.c
	gcc -fPIC -shared $< -o $@

# ###########################################################
