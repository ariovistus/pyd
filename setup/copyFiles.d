static import std.file;

void main()
{
	std.file.write("pyd_get_env_set_text.py", import("pyd_get_env_set_text.py"));
	version (Posix)
		std.file.write("pyd_set_env_vars.sh", import("pyd_set_env_vars.sh"));
	version (Windows)
		std.file.write("pyd_set_env_vars.bat", import("pyd_set_env_vars.bat"));
}
