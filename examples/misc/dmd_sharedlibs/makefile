# ###########################################################
BITSI = 
ifeq ($(BITSI), 32)
DMD_M=-m32
GCC_M=-m32
else	
ifeq ($(BITSI), 64)
DMD_M=-m64
GCC_M=-m64
else
DMD_M=
GCC_M=
endif
endif
DMD=dmd $(DMD_M)
GCC=gcc $(GCC_M)


# build a shared lib with d, link to it from c.
test1: test1.x libtest1.so
	./test1.x
# build two shared libs with d, link to both from c.
test2: test2.x libtest2a.so libtest2b.so
	./test2.x
test3: test3.x libtest3.so
	./test3.x
clean:
	rm -f *.o
	rm -f *.so
	rm -f *.x

lib%.so: %.d boilerplate.d so_ctor.o
	$(DMD) -unittest -fPIC -defaultlib=libphobos2.so -shared $^ -of$@
	#$(DMD) -c -unittest -fPIC $< boilerplate.d -oftemp.o
	#$(DMD) -shared -defaultlib=phobos2so temp.o so_ctor.o -of$@
so_ctor.o: so_ctor.c
	$(GCC) -c -fPIC so_ctor.c -o so_ctor.o

test1.x: test1.c libtest1.so
	$(GCC) $< `pwd`/libtest1.so -o $@
test2.x: test2.c libtest2a.so libtest2b.so
	$(GCC) $< `pwd`/libtest2a.so `pwd`/libtest2b.so -o $@
test3.x: test3.d libtest3.so
	dmd $< -L`pwd`/libtest3.so -of$@ 
libtest3.so: test3lib.c
	gcc -fPIC -shared $< -o $@

# ###########################################################
