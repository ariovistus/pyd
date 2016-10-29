/**
  Mirror _structmember.h

Interface to map C struct members to Python object attributes
*/
module deimos.python.structmember;

import deimos.python.pyport;
import deimos.python.object;

extern(C):
// Python-header-file: Include/structmember.h:

/// _
struct PyMemberDef {
    /** Current version, use this */
    char* name;
    /// _
    int type;
    /// _
    Py_ssize_t offset;
    /// _
    int flags;
    /// _
    char* doc;
}

/** Types */
enum T_SHORT = 0;
/// ditto
enum T_INT = 1;
/// ditto
enum T_LONG = 2;
/// ditto
enum T_FLOAT = 3;
/// ditto
enum T_DOUBLE = 4;
/// ditto
enum T_STRING = 5;
/// ditto
enum T_OBJECT = 6;
/// ditto
enum T_CHAR = 7;
/// ditto
enum T_BYTE = 8;
/// ditto
enum T_UBYTE = 9;
/// ditto
enum T_USHORT = 10;
/// ditto
enum T_UINT = 11;
/// ditto
enum T_ULONG = 12;
/// ditto
enum T_STRING_INPLACE = 13;
version(Python_2_6_Or_Later){
    /// Availability: >= 2.6
    enum T_BOOL = 14;
}
/// _
enum T_OBJECT_EX = 16;
version(Python_2_5_Or_Later){
    /// Availability: >= 2.5
    enum T_LONGLONG = 17;
    /// Availability: >= 2.5
    enum T_ULONGLONG = 18;
}
version(Python_2_6_Or_Later){
    /// Availability: >= 2.6
    enum T_PYSSIZET = 19;
}
version(Python_3_2_Or_Later) {
    /// Availability: >= 3.2
    enum T_NONE = 20;
}

/// _
enum READONLY = 1;
/// _
alias READONLY RO;
/// _
enum READ_RESTRICTED = 2;
/// _
enum WRITE_RESTRICTED = 4;
/// _
enum RESTRICTED = (READ_RESTRICTED | WRITE_RESTRICTED);

/// _
PyObject* PyMember_GetOne(const(char)*, PyMemberDef*);
/// _
int PyMember_SetOne(char*, PyMemberDef*, PyObject*);


