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
PYTHON = pypy

test1: libtest1.so test1.py
	$(PYTHON) test1.py
so_ctor.o: so_ctor.c
	$(GCC) -c -fPIC so_ctor.c -o so_ctor.o

libtest1.so: test1.d boilerplate.d so_ctor.o 
	$(DMD) -unittest -fPIC -defaultlib=phobos2so -shared $^ -of$@
