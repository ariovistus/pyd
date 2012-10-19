
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
$global:args = $DC + $PYTHON_2_7 + $PYD_FILES + @("-I..\..\infrastructure\")

$dfiles = ls *.d | where {$_ -match ".*[^3]\.d"}

$dfiles | foreach {`
    . "dmd" ($global:args + @($_, "-of$($_.BaseName).exe")) }

#. "dmd" ($global:args + @("class_wrap.d", "-ofclass_wrap.exe")) 
#. ".\class_wrap.exe"
$dfiles | foreach {. ".\$($_.BaseName).exe" }
