
PYD_DIR = ../../infrastructure/
PYD_FILES = $(shell find ../../infrastructure/pyd/ -name \*.d) \
$(shell find ../../infrastructure/meta/ -name \*.d) \
$(shell find ../../infrastructure/util/ -name \*.d) 
LDC_PYTHON_2_7 = -d-version=Python_2_7_Or_Later \
             -d-version=Python_2_6_Or_Later \
	     -d-version=Python_2_5_Or_Later \
	     -d-version=Python_2_4_Or_Later \
	     -L-lpython2.7
PYTHON_2_7_static = -version=Python_2_7_Or_Later \
             -version=Python_2_6_Or_Later \
	     -version=Python_2_5_Or_Later \
	     -version=Python_2_4_Or_Later \
	     /usr/lib/python2.7/config/libpython2.7.a 
PYTHON_2_7 = -version=Python_2_7_Or_Later \
             -version=Python_2_6_Or_Later \
	     -version=Python_2_5_Or_Later \
	     -version=Python_2_4_Or_Later \
	     -L-lpython2.7
PYTHON_3_2 = -version=Python_3_2_Or_Later \
	     -version=Python_3_1_Or_Later \
	     -version=Python_3_0_Or_Later \
	     -version=Python_2_7_Or_Later \
             -version=Python_2_6_Or_Later \
	     -version=Python_2_5_Or_Later \
	     -version=Python_2_4_Or_Later \
	     -L-lpython3.2mu
DC = dmd -unittest -property -debug -gc
LDC = ldc2 -unittest -property -d-debug -gc -oq

all: pydobject.x pydobject3.x make_object.x make_object3.x embedded.x embedded3.x func_wrap.x func_wrap3.x class_wrap.x class_wrap3.x def.x def3.x struct_wrap.x threading.x
	./pydobject.x
	./pydobject3.x
	./make_object.x
	./make_object3.x
	./embedded.x
	./embedded3.x
	./func_wrap.x
	./func_wrap3.x
	./class_wrap.x
	./class_wrap3.x
	./struct_wrap.x
	./def.x
	./def3.x
	./threading.x

clean:
	rm -f *.x
	rm -f *.o

%3.x: %3.d
	$(DC) $(PYTHON_3_2) $(PYD_FILES) $^ -of$@ -I$(PYD_DIR)
%.x: %.d
	#$(DC) $(PYTHON_2_7) $(PYD_FILES) $^ -of$@ -I$(PYD_DIR)
	$(LDC) $(LDC_PYTHON_2_7) $(PYD_FILES) $^ -of $@ -I$(PYD_DIR)

