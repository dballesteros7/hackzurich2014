#include <Python.h>

const char * getNotes() {
    PyObject *pModuleName, *pModule, *pFunc;
    PyObject *pResult;

    Py_Initialize();
    pModuleName = PyString_FromString("evernote_client");
    pModule = PyImport_Import(pModuleName);
    Py_DECREF(pModuleName);

    if (pModule != NULL) {
        pFunc = PyObject_GetAttrString(pModule, "retrieve_note_content");

        pResult = PyObject_CallObject(pFunc, NULL);

        printf(PyString_AsString(pResult));

        Py_DECREF(pResult);
        Py_DECREF(pFunc);
        Py_DECREF(pModule);
    } else {
        PyErr_Print();
        fprintf(stderr, "Failed to load evernote_client\n");
        return 0;
    }
    Py_Finalize();
    return 0;
}
