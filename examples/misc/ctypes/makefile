LDC=ldc2

LIBS= -Wl,--no-as-needed -lphobos-ldc -ldruntime-ldc -lrt -lpthread -ldl -lm 

# convert a D string to python unicode
test4: test4.py libtest4.so
	python test4.py
# raise a python exception in D
test3: test3.py libtest3.so
	python test3.py
test2: test2.py libtest2.so
	python test2.py
# convert a d integer to python int
test1: test1.py libtest1.so
	python test1.py

clean:
	rm -f *.so
	rm -f *.o

lib%.so: %.o boilerplate.o common.o
	echo "building $@"
	gcc -nostartfiles -shared $(LIBS) $^ -o $@ 
	#gcc -shared $^ -o $@
boilerplate.d: ../../../infrastructure/d/python_so_linux_boilerplate.d
	cp $< $@
	echo "extern(C) void _Dmain(){}" >> $@
%.o: %.d 
	echo "building $@"
	$(LDC) -relocation-model=pic -c $^ -of $@
	#gcc -fPIC -c $^ -o $@
