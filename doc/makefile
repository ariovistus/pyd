PYD = ../infrastructure/
FILES = $(shell find $(PYD)/util $(PYD)/pyd $(PYD)/meta -name \*.d) $(PYD)/python/python.d 
PYTHON_2_7 = -version=Python_2_7_Or_Later \
             -version=Python_2_6_Or_Later \
	     -version=Python_2_5_Or_Later \
	     -version=Python_2_4_Or_Later 
all:
	dmd -o- candydoc/candy.ddoc candydoc/modules.ddoc -Dd. $(FILES) $(PYTHON_2_7)

clean:
	rm -f *.o
	rm -f *.html
