/**
  Mirror import.h

  Module definition and import interface
  */
module deimos.python.import_;

import deimos.python.pyport;
import deimos.python.object;
import core.stdc.stdio;

extern(C):
// Python-header-file: Include/import.h:

/// _
C_long PyImport_GetMagicNumber();
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    const(char)* PyImport_GetMagicTag();
}
/// _
PyObject* PyImport_ExecCodeModule(char* name, PyObject* co);
/// _
PyObject* PyImport_ExecCodeModuleEx(char* name, PyObject* co, char* pathname);
version(Python_3_0_Or_Later) {
    /**
Params:
name = UTF-8 encoded string
co =
pathname = decoded from the filesystem encoding
cpathname = decoded from the filesystem encoding
     */
    /// Availability: 3.*
    PyObject* PyImport_ExecCodeModuleWithPathnames(
            char* name,
            PyObject* co,
            char* pathname,
            char* cpathname
            );
}
/// _
PyObject* PyImport_GetModuleDict();

version(Python_3_7_Or_Later) {
    PyObject* PyImport_GetModule(PyObject* name);
}

/// _
PyObject* PyImport_AddModule(const(char)* name);
/// _
PyObject* PyImport_ImportModule(const(char)* name);

version(Python_2_5_Or_Later){
    /// Availability: >= 2.5
    PyObject* PyImport_ImportModuleLevel(char* name,
            PyObject* globals, PyObject* locals, PyObject* fromlist,
            int level);
}
version(Python_2_6_Or_Later){
    /// Availability: >= 2.6
    PyObject*  PyImport_ImportModuleNoBlock(const(char)* name);
}
version(Python_2_5_Or_Later){
    /// _
    PyObject* PyImport_ImportModuleEx()(char* n, PyObject* g, PyObject* l,
            PyObject* f) {
        return PyImport_ImportModuleLevel(n, g, l, f, -1);
    }
}else{
    /// _
    PyObject* PyImport_ImportModuleEx(char* , PyObject* , PyObject* , PyObject* );
}

version(Python_2_6_Or_Later){
    /// Availability: >= 2.6
    PyObject* PyImport_GetImporter(PyObject* path);
}
/// _
PyObject* PyImport_Import(PyObject* name);
/// _
PyObject* PyImport_ReloadModule(PyObject* m);
/// _
void PyImport_Cleanup();
/// _
int PyImport_ImportFrozenModule(char* );

version(Python_3_0_Or_Later) {
    /**
Params:
name = UTF-8 encoded string
*/
    version(Python_3_7_Or_Later) {
        /// Availability: 3.*
        PyObject* _PyImport_FindBuiltin(
                char* name,
                PyObject* modules
                );
    }else{
        /// Availability: 3.*
        PyObject* _PyImport_FindBuiltin(
                char* name
                );
    }
    /// Availability: 3.*
    PyObject* _PyImport_FindExtensionUnicode(char*, PyObject*);
    /**
Params:
mod =
name = UTF-8 encoded string
*/
    version(Python_3_7_Or_Later) {
        /// Availability: 3.*
        int _PyImport_FixupBuiltin(
            PyObject* mod,
            char* name,
            PyObject* modules
            );
    }else{
        /// Availability: 3.*
        int _PyImport_FixupBuiltin(
            PyObject* mod,
            char* name
            );
    }
    /// Availability: 3.*
    int _PyImport_FixupExtensionUnicode(PyObject*, char*, PyObject*);
}else {
    struct filedescr; // TODO: what the heck is this?
    /// Availability: 2.*
    filedescr* _PyImport_FindModule(
            const(char)*, PyObject*, char*, size_t, FILE**, PyObject**);
    /// Availability: 2.*
    int _PyImport_IsScript(filedescr*);
}
/// _
void _PyImport_ReInitLock();

/// _
PyObject* _PyImport_FindExtension(char* , char* );
/// _
PyObject* _PyImport_FixupExtension(char* , char* );

/// _
struct _inittab {
    /// _
    char* name;
    version(Python_3_0_Or_Later) {
        /// Availability: 3.*
        PyObject* function() initfunc;
    }else{
        /// Availability: 2.*
        void function() initfunc;
    }
}

/// _
mixin(PyAPI_DATA!"PyTypeObject PyNullImporter_Type");
/// _
mixin(PyAPI_DATA!"_inittab* PyImport_Inittab");

version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    int PyImport_AppendInittab(const(char)* name, PyObject* function() initfunc);
}else {
    /// Availability: 2.*
    int PyImport_AppendInittab(const(char)* name, void function() initfunc);
}
/// _
int PyImport_ExtendInittab(_inittab *newtab);

/// _
struct _frozen {
    /// _
    char* name;
    /// _
    ubyte *code;
    /// _
    int size;
}

/** Embedding apps may change this pointer to point to their favorite
   collection of frozen modules: */
mixin(PyAPI_DATA!"_frozen* PyImport_FrozenModules");

