module deimos.python.import_;

import deimos.python.pyport;
import deimos.python.object;
import std.c.stdio;

extern(C):
// Python-header-file: Include/import.h:

C_long PyImport_GetMagicNumber();
version(Python_3_0_Or_Later) {
    const(char)* PyImport_GetMagicTag();
}
PyObject* PyImport_ExecCodeModule(char* name, PyObject* co);
PyObject* PyImport_ExecCodeModuleEx(char* name, PyObject* co, char* pathname);
version(Python_3_0_Or_Later) {
    PyObject* PyImport_ExecCodeModuleWithPathnames(
            char* name,                 /* UTF-8 encoded string */
            PyObject *co,
            char* pathname,             /* decoded from the filesystem encoding */
            char* cpathname             /* decoded from the filesystem encoding */
            );
}
PyObject* PyImport_GetModuleDict();
PyObject* PyImport_AddModule(Char1* name);
PyObject* PyImport_ImportModule(Char1* name);

version(Python_2_5_Or_Later){
    PyObject* PyImport_ImportModuleLevel(char* name,
            PyObject* globals, PyObject* locals, PyObject* fromlist, 
            int level);
}
version(Python_2_6_Or_Later){
    PyObject*  PyImport_ImportModuleNoBlock(const(char)* name);
}
version(Python_2_5_Or_Later){
    PyObject* PyImport_ImportModuleEx()(char* n, PyObject* g, PyObject* l, 
            PyObject* f) {
        return PyImport_ImportModuleLevel(n, g, l, f, -1);
    }
}else{
    PyObject* PyImport_ImportModuleEx(char* , PyObject* , PyObject* , PyObject* );
}

version(Python_2_6_Or_Later){
    PyObject*  PyImport_GetImporter(PyObject* path);
}
PyObject* PyImport_Import(PyObject* name);
PyObject* PyImport_ReloadModule(PyObject* m);
void PyImport_Cleanup();
int PyImport_ImportFrozenModule(char* );

version(Python_3_0_Or_Later) {
    PyObject* _PyImport_FindBuiltin(
            char* name                  /* UTF-8 encoded string */
            );
    PyObject* _PyImport_FindExtensionUnicode(char*, PyObject*);
    int _PyImport_FixupBuiltin(
            PyObject* mod,
            char* name                  /* UTF-8 encoded string */
            );
    int _PyImport_FixupExtensionUnicode(PyObject*, char*, PyObject*);
}else {
    struct filedescr; // TODO: what the heck is this?
    filedescr* _PyImport_FindModule(
            const(char)*, PyObject*, char*, size_t, FILE**, PyObject**);
    int _PyImport_IsScript(filedescr*);
}
void _PyImport_ReInitLock();

PyObject* _PyImport_FindExtension(char* , char* );
PyObject* _PyImport_FixupExtension(char* , char* );

struct _inittab {
    char* name;
    version(Python_3_0_Or_Later) {
        PyObject* function() initfunc;
    }else{
        void function() initfunc;
    }
}

__gshared PyTypeObject PyNullImporter_Type;
__gshared _inittab* PyImport_Inittab;

version(Python_2_7_Or_Later){
    alias const(char) Char2;
}else{
    alias char Char2;
}

version(Python_3_0_Or_Later) {
    int PyImport_AppendInittab(Char2* name, PyObject* function() initfunc);
}else {
    int PyImport_AppendInittab(Char2* name, void function() initfunc);
}
int PyImport_ExtendInittab(_inittab *newtab);

struct _frozen {
    char* name;
    ubyte *code;
    int size;
}

__gshared _frozen* PyImport_FrozenModules;

