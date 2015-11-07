#include <Python.h>
#include <stdio.h>

typedef struct {
} x_XObject;

static PyTypeObject x_XType = {
    PyVarObject_HEAD_INIT(NULL, 0) 
    "x.X",                     /*tp_name*/
    sizeof(x_XObject),         /*tp_basicsize*/
    0,                         /*tp_itemsize*/
    0,                         /*tp_dealloc*/
    0,                         /*tp_print*/
    0,                         /*tp_getattr*/
    0,                         /*tp_setattr*/
    0,                         /*tp_compare*/
    0,                         /*tp_repr*/
    0,                         /*tp_as_number*/
    0,                         /*tp_as_sequence*/
    0,                         /*tp_as_mapping*/
    0,                         /*tp_hash */
    0,                         /*tp_call*/
    0,                         /*tp_str*/
    0,                         /*tp_getattro*/
    0,                         /*tp_setattro*/
    0,                         /*tp_as_buffer*/
    Py_TPFLAGS_DEFAULT,        /*tp_flags*/
    "X objects",               /* tp_doc */
};

static PyMethodDef x_methods[] = {
    {NULL} /*sentinal*/
};

PyObject *x_add(PyObject * arg1, PyObject * arg2) 
{
    return Py_BuildValue("OO", arg1, arg2);
}


#ifndef PyMODINIT_FUNC
#define PyMODINIT_FUNC void
#endif

#if PY_MAJOR_VERSION >= 3
struct module_state {
    PyObject *error;
};
#define GETSTATE(m) ((struct module_state*)PyModule_GetState(m))
static int x_traverse(PyObject *m, visitproc visit, void *arg) {
    Py_VISIT(GETSTATE(m)->error);
    return 0;
}
static int x_clear(PyObject *m) {
    Py_CLEAR(GETSTATE(m)->error);
    return 0;
}
static struct PyModuleDef moduledef = {
    PyModuleDef_HEAD_INIT,
    "x",
    NULL,
    -1,
    x_methods,
    NULL,
    NULL,
    x_clear,
    NULL
};
PyObject *PyInit_x(void)
#else
    PyMODINIT_FUNC
initx(void)
#endif
{
    PyObject* m;

    x_XType.tp_new = PyType_GenericNew;
    x_XType.tp_as_number = (PyNumberMethods *) malloc(sizeof(PyNumberMethods));
    memset(x_XType.tp_as_number, 0, sizeof(PyNumberMethods));
    x_XType.tp_as_number->nb_add = &x_add; 


#if PY_MAJOR_VERSION >= 3
    m = PyModule_Create(&moduledef);
#else

    // this is important!
    x_XType.tp_flags |= Py_TPFLAGS_CHECKTYPES;
    m = Py_InitModule3("x", x_methods, "Hi ho, pipsissiwa is slow");
#endif
    if(PyType_Ready(&x_XType) < 0) return NULL;

    Py_INCREF(&x_XType);
    PyModule_AddObject(m, "X", (PyObject *)&x_XType);
#if PY_MAJOR_VERSION >= 3
    return m;
#endif
}
