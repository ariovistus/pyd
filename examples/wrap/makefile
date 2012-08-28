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
DC = dmd -m64 -unittest -property -debug
all: 
	echo 'import sys; sys.path.append("../../build/lib/");' > tsetup.py
	cat setup.py >> tsetup.py
	python tsetup.py build

clean:
	rm -rf build
	rm -f tsetup.py

wraptest.o: wraptest.d
	$(DC) -c $(PYTHON_2_7) $(PYTHON_HEADER) $(PYD_FILES) $^ -of$@
