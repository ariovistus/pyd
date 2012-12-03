
$DC = @("-unittest", "-property", "-debug")

$PYTHON_2_7_VERSION = @(
            "-version=Python_2_7_Or_Later",
            "-version=Python_2_6_Or_Later",
            "-version=Python_2_5_Or_Later",
            "-version=Python_2_4_Or_Later",
            "-version=Python_Unicode_UCS2")
$PYTHON_2_7 = $PYTHON_2_7_VERSION 
$PYTHON_2_7 += @(
            "..\..\infrastructure\python\python27_digitalmars.lib")

$PYTHON_3_2 = $PYTHON_2_7_VERSION
$PYTHON_3_2 += @(
            "-version=Python_3_0_Or_Later",
            "-version=Python_3_1_Or_Later",
            "-version=Python_3_2_Or_Later",
            "..\..\infrastructure\python\python32_digitalmars.lib")
$PYD_FILES = ls ../../infrastructure/pyd/ *.d -recurse | foreach-object { $_.FullName } 
$PYD_FILES += ls ../../infrastructure/meta/ *.d -recurse | foreach-object { $_.FullName } 
$PYD_FILES += ls ../../infrastructure/util/ *.d -recurse | foreach-object { $_.FullName } 
$PYD_FILES += ls ../../infrastructure/deimos/ *.d -recurse | foreach-object { $_.FullName } 
$args = $DC + $PYTHON_2_7 + $PYD_FILES + @("pyind.d","-I..\..\infrastructure\", "-ofpyind.exe")
#. "dmd" $args


$args3 = $DC + $PYTHON_3_2 + $PYD_FILES + @("pyind3.d","-I..\..\infrastructure\", "-ofpyind3.exe")
echo "dmd $args3"
. "dmd" $args3

