module deimos.python.errcode;

enum E_OK                   = 10;
enum E_EOF                  = 11;
enum E_INTR                 = 12;
enum E_TOKEN                = 13;
enum E_SYNTAX               = 14;
enum E_NOMEM                = 15;
enum E_DONE                 = 16;
enum E_ERROR                = 17;
enum E_TABSPACE             = 18;
enum E_OVERFLOW             = 19;
enum E_TOODEEP              = 20;
enum E_DEDENT               = 21;
enum E_DECODE               = 22;
enum E_EOFS                 = 23;
enum E_EOLS                 = 24;
enum E_LINECONT             = 25;
version(Python_3_0_Or_Later) {
enum E_IDENTIFIER           = 26;
}
