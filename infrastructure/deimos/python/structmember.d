module deimos.python.structmember;

import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/structmember.h:

struct PyMemberDef {
  char* name;
  int type;
  Py_ssize_t offset;
  int flags;
  char* doc;
}

enum T_SHORT = 0;
enum T_INT = 1;
enum T_LONG = 2;
enum T_FLOAT = 3;
enum T_DOUBLE = 4;
enum T_STRING = 5;
enum T_OBJECT = 6;
enum T_CHAR = 7;
enum T_BYTE = 8;
enum T_UBYTE = 9;
enum T_USHORT = 10;
enum T_UINT = 11;
enum T_ULONG = 12;
enum T_STRING_INPLACE = 13;
version(Python_2_6_Or_Later){
    enum T_BOOL = 14;
}
enum T_OBJECT_EX = 16;
version(Python_2_5_Or_Later){
    enum T_LONGLONG = 17;
    enum T_ULONGLONG = 18;
}
version(Python_2_6_Or_Later){
    enum T_PYSSIZET = 19;
}
version(Python_3_2_Or_Later) {
    enum T_NONE = 20;
}

enum READONLY = 1;
alias READONLY RO;
enum READ_RESTRICTED = 2;
enum WRITE_RESTRICTED = 4;
enum RESTRICTED = (READ_RESTRICTED | WRITE_RESTRICTED);

PyObject* PyMember_GetOne(Char1*, PyMemberDef*);
int PyMember_SetOne(char*, PyMemberDef*, PyObject*);


