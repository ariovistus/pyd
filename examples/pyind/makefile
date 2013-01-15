PYD_DIR = ../../infrastructure/
PYD_FILES = $(shell find ../../infrastructure/pyd/ -name \*.d) \
$(shell find ../../infrastructure/meta/ -name \*.d) \
$(shell find ../../infrastructure/util/ -name \*.d) 
DEIMOS_FILES = $(shell find ../../infrastructure/deimos/ -name \*.d) 
PYTHON_2_7_LDC = -d-version=Python_2_7_Or_Later \
             -d-version=Python_2_6_Or_Later \
	     -d-version=Python_2_5_Or_Later \
	     -d-version=Python_2_4_Or_Later \
	     -L-lpython2.7
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
DC = dmd -unittest -property -debug -g 
LDC = ldc2 -unittest -property 
#DC = ldmd2 -unittest -property -debug -gc
all: pyind pyind3
clean:
	rm -f *.o
	rm -f pyind
	rm -f pyind3
pyind3: pyind3.d
	$(DC) $(PYTHON_3_2) $(PYD_FILES) $^ -of$@ -I../../infrastructure/ 
pyind: pyind.d
	$(DC) $(PYTHON_2_7) $(PYD_FILES) $^ -of$@ -I../../infrastructure/ 
	#$(LDC) $(PYTHON_2_7_LDC) $(PYD_FILES) $(DEIMOS_FILES) $^ -of $@ -I../../infrastructure/
