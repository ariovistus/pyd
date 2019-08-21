@echo off

if "%~1"=="" (
	echo python interpreter not specified, using ""python""
	set PYD_PYTHON=python
) else (
	set PYD_PYTHON=%~1
)

"%PYD_PYTHON%" "%~dp0\pyd_get_env_set_text.py" > tmp_pyd_env_set.bat
if %errorlevel% neq 0 exit /b %errorlevel%
call tmp_pyd_env_set.bat
set result=%errorlevel%
del tmp_pyd_env_set.bat
if %errorlevel% neq 0 exit /b %errorlevel%
exit /b %result%
