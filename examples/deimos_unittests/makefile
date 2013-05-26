PYD_DIR = ../../infrastructure/
PYTHON_2_7_static = -version=Python_2_7_Or_Later \
             -version=Python_2_6_Or_Later \
	     -version=Python_2_5_Or_Later \
	     -version=Python_2_4_Or_Later \
	     -L/usr/lib/python2.7/config/libpython2.7.a \
             -L-ldl -L-lutil
PYTHON_2_7 = -version=Python_2_7_Or_Later \
             -version=Python_2_6_Or_Later \
	     -version=Python_2_5_Or_Later \
	     -version=Python_2_4_Or_Later \
	     -L-lpython2.7
PYTHON_3_3 = -version=Python_3_3_Or_Later \
	     -version=Python_3_2_Or_Later \
	     -version=Python_3_1_Or_Later \
	     -version=Python_3_0_Or_Later \
	     -version=Python_2_7_Or_Later \
             -version=Python_2_6_Or_Later \
	     -version=Python_2_5_Or_Later \
	     -version=Python_2_4_Or_Later \
	     -L-lpython3.3m
PYTHON_2_7_LDC = -d-version=Python_2_7_Or_Later \
             -d-version=Python_2_6_Or_Later \
	     -d-version=Python_2_5_Or_Later \
	     -d-version=Python_2_4_Or_Later \
	     -L-lpython2.7
PYD_FILES = $(shell find $(PYD_DIR)/deimos/ -name \*.d )
DC = dmd -unittest -property -debug -gc 
LDC = ldc2 -unittest -property -d-debug=1 -gc 

all: object_.x

clean:
	rm -f *.x
	rm -f *.o

%.x: %.d
	$(DC) $(PYTHON_2_7_static) $< -of$@  -I$(PYD_DIR)   -v
none:
	#$(LDC) -of $@ $(PYTHON_2_7_LDC) $< -I$(PYD_DIR) $(PYD_FILES)

