
$PYTHON_2_7 = @(
            "-version=Python_2_7_Or_Later",
            "-version=Python_2_6_Or_Later",
            "-version=Python_2_5_Or_Later",
	        "-version=Python_2_4_Or_Later",
            "-version=Python_Unicode_UCS2",
	        "..\..\infrastructure\python/python27_digitalmars.lib")
dmd (@("object_.d", "-unittest", "-I..\..\infrastructure\") + $PYTHON_2_7)
