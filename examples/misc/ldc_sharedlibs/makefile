# ###########################################################
# from fedora repos
LDC=ldc2

# build a shared library written in D, main program written in C.
test1: test1.x libtest1.so
	./test1.x

# build 2 shared libraries written in D, main program written in C.
# not working: druntime needs some tlc.
test2: test2.x libtest2a.so libtest2b.so
	./test2.x
# build a shared library written in C with global data. Access global data in D
test3: test3.x libtest3.so
	./test3.x
clean:
	rm -f *.o
	rm -f *.so
	rm -f *.x

LIBS= -L--no-as-needed -L-lphobos-ldc -L-ldruntime-ldc -L-lrt -L-lpthread -L-ldl -L-lm -L-lpython2.7

%.o: %.d
	echo "building $@"
	$(LDC) -unittest -relocation-model=pic -c $^ -of $@

lib%.so: %.o boilerplate.o
	echo "building $@"
	ldc2 -shared $(LIBS) $^ -of $@

test1.x: test1.c libtest1.so
	echo "building $@"
	gcc $< `pwd`/libtest1.so -o $@

test2.x: test2.c libtest2a.so libtest2b.so
	echo "building $@"
	gcc $< `pwd`/libtest2a.so `pwd`/libtest2b.so -o $@

test3.x: test3.d libtest3.so
	$(LDC) $< -L`pwd`/libtest3.so -of $@
libtest3.so: test3lib.c
	gcc -fPIC -shared $< -o $@

# ###########################################################
