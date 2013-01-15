PYD_DIR = ../../infrastructure/
PYTHON_2_7 = -version=Python_2_7_Or_Later \
             -version=Python_2_6_Or_Later \
	     -version=Python_2_5_Or_Later \
	     -version=Python_2_4_Or_Later \
	     -L-lpython2.7
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
	$(DC) $(PYTHON_2_7) $< -of$@  -I$(PYD_DIR) -v
	#$(LDC) -of $@ $(PYTHON_2_7_LDC) $< -I$(PYD_DIR) $(PYD_FILES)

