all: 
	echo 'import sys; sys.path.append("../../build/lib/");' > tsetup.py
	cat setup.py >> tsetup.py
	python tsetup.py build

clean:
	rm -rf build
	rm -f tsetup.py
