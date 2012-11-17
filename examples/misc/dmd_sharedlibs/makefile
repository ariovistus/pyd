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
	LD_LIBRARY_PATH=. ./test1.x
# build two shared libs with d, link to both from c.
test2: test2.x libtest2a.so libtest2b.so
	LD_LIBRARY_PATH=. ./test2.x
test3: test3.x libtest3.so
	LD_LIBRARY_PATH=. ./test3.x
clean:
	rm -f *.o
	rm -f *.so
	rm -f *.x

lib%.so: %.d boilerplate.d test1helper.o 
	$(DMD) -unittest -fPIC -shared $^ -of$@
test1helper.o: test1helper.c
	$(GCC) -c test1helper.c -o test1helper.o

test1.x: test1.c libtest1.so
	LD_LIBRARY_PATH=. $(GCC) $< -L. -ltest1 -o $@
test2.x: test2.c libtest2a.so libtest2b.so
	LD_LIBRARY_PATH=. $(GCC) $< -L. -ltest2a -ltest2b -o $@
test3.x: test3.d libtest3.so
	LD_LIBRARY_PATH=. dmd $< -L-L. -L-ltest3 -of$@ 
libtest3.so: test3lib.c
	gcc -fPIC -shared $< -o $@

# ###########################################################
