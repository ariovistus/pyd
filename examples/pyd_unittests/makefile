
PYTHON_HEADER = ../../infrastructure/python/python.d
PYD_DIR = ../../infrastructure/
PYD_FILES = $(shell find ../../infrastructure/pyd/ -name \*.d) \
$(shell find ../../infrastructure/meta/ -name \*.d) \
$(shell find ../../infrastructure/util/ -name \*.d) 
PYTHON_2_7 = -version=Python_2_7_Or_Later \
             -version=Python_2_6_Or_Later \
	     -version=Python_2_5_Or_Later \
	     -version=Python_2_4_Or_Later \
	     -L-lpython2.7
DC = dmd -unittest -property -debug

all: pydobject.x make_object.x embedded.x func_wrap.x class_wrap.x def.x struct_wrap.x buffer.x
	./pydobject.x
	./make_object.x
	./embedded.x
	./func_wrap.x
	./class_wrap.x
	./struct_wrap.x
	./def.x
	./buffer.x

clean:
	rm -f *.x
	rm -f *.o

%.x: %.d
	$(DC) $(PYTHON_2_7) $(PYTHON_HEADER) $(PYD_FILES) $^ -of$@

