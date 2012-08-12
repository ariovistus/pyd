# ###########################################################
# from fedora repos
LDC=ldc2

test1: test1.x libtest1.so
	LD_LIBRARY_PATH=. ./test1.x
clean:
	rm -f *.o
	rm -f *.so
	rm -f *.x

LIBS= -lphobos-ldc -ldruntime-ldc -lrt -lpthread -ldl -lm -lpython2.7

test1.o: test1.d
	$(LDC) -relocation-model=pic -c $^ -of $@

libtest1.so: test1.o
	gcc -nostartfiles -shared $(LIBS) $^ -o $@ 

test1.x: test1.c libtest1.so
	LD_LIBRARY_PATH=. gcc $< -L. -ltest1 -o $@

# ###########################################################
