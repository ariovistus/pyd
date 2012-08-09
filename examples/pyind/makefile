PYTHON_HEADER = ../../infrastructure/python/python.d
PYD_DIR = ../../infrastructure/
PYD_FILES = $(shell find ../../infrastructure/pyd/ -name \*.d ! -name iteration.d) \
$(shell find ../../infrastructure/meta/ -name \*.d) 
#../../infrastructure/st/stackcontext.d
#$(shell find ../../infrastructure/st/ -name \*.d)
PYTHON_2_7 = -version=Python_2_7_Or_Later \
             -version=Python_2_6_Or_Later \
	     -version=Python_2_5_Or_Later \
	     -version=Python_2_4_Or_Later \
	     -L-lpython2.7
DC = dmd -m32 -unittest -property -debug
all: pyind
clean:
	rm -f *.o
	rm -f pyind
pyind: pyind.d
	$(DC) $(PYTHON_2_7) $(PYTHON_HEADER) $(PYD_FILES) $(META_FILES) $^ -of$@
