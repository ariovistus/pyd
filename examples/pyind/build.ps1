
$DC = @("-unittest", "-property", "-debug")

$PYTHON_2_7 = @(
            "-version=Python_2_7_Or_Later",
            "-version=Python_2_6_Or_Later",
            "-version=Python_2_5_Or_Later",
	        "-version=Python_2_4_Or_Later",
            "-version=Python_Unicode_UCS2",
	        "..\..\infrastructure\python/python27_digitalmars.lib")
$PYD_FILES = ls ../../infrastructure/pyd/ *.d -recurse | foreach-object { $_.FullName } 
$PYD_FILES += ls ../../infrastructure/meta/ *.d -recurse | foreach-object { $_.FullName } 
$PYD_FILES += ls ../../infrastructure/util/ *.d -recurse | foreach-object { $_.FullName } 
$args = $DC + $PYTHON_2_7 + $PYD_FILES + @("pyind.d","-I..\..\infrastructure\", "-ofpyind.exe")
. "dmd" $args

