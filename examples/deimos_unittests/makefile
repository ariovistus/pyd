PYD_DIR = ../../infrastructure/
PYTHON_2_7 = -version=Python_2_7_Or_Later \
             -version=Python_2_6_Or_Later \
	     -version=Python_2_5_Or_Later \
	     -version=Python_2_4_Or_Later \
	     -L-lpython2.7
DC = dmd -unittest -property -debug -gc

all: object_.x

clean:
	rm -f *.x
	rm -f *.o

%.x: %.d
	$(DC) $(PYTHON_2_7) $< -of$@  -I$(PYD_DIR)
