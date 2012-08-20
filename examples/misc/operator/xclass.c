#include <Python.h>
#include <stdio.h>

typedef struct {
} x_XObject;

static PyTypeObject x_XType = {
    PyObject_HEAD_INIT(NULL) 0,/*ob_size*/
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

PyMODINIT_FUNC
initx(void)
{
    PyObject* m;

    x_XType.tp_new = PyType_GenericNew;
    x_XType.tp_as_number = (PyNumberMethods *) malloc(sizeof(PyNumberMethods));
    memset(x_XType.tp_as_number, 0, sizeof(PyNumberMethods));
    x_XType.tp_as_number->nb_add = &x_add; 

    // this is important!
    x_XType.tp_flags |= Py_TPFLAGS_CHECKTYPES;

    if(PyType_Ready(&x_XType) < 0) return;

    m = Py_InitModule3("x", x_methods, "Hi ho, pipsissiwa is slow");

    Py_INCREF(&x_XType);
    PyModule_AddObject(m, "X", (PyObject *)&x_XType);
}
