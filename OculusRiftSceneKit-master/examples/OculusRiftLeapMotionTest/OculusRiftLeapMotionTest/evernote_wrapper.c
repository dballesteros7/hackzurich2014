#include <Python.h>
extern char **environ;

const char * getNotes() {
        PyObject *pModuleName, *pModule, *pFunc;
        PyObject *pResult;
        char *returnVal;

        Py_Initialize();
        pModuleName = PyString_FromString("evernote_client");
        pModule = PyImport_Import(pModuleName);
        Py_DECREF(pModuleName);

        if (pModule != NULL) {
            pFunc = PyObject_GetAttrString(pModule, "retrieve_note_content");

            pResult = PyObject_CallObject(pFunc, NULL);

            returnVal = PyString_AsString(pResult);

            Py_DECREF(pResult);
            Py_DECREF(pFunc);
            Py_DECREF(pModule);
        } else {
            PyErr_Print();
            fprintf(stderr, "Failed to load evernote_client\n");
            return "-1";
        }
        Py_Finalize();
        return returnVal;
    }

    void makeNote(const char *imagePath ) {
        PyObject *pModuleName, *pModule, *pFunc, *pArgs;
        
        for (char **env = environ; *env; ++env)
            printf("%s\n", *env);

        Py_Initialize();
        pModuleName = PyString_FromString("evernote_client");
        pModule = PyImport_Import(pModuleName);
        Py_DECREF(pModuleName);

        if (pModule != NULL) {
            pFunc = PyObject_GetAttrString(pModule, "make_note");
            pArgs = PyTuple_New(1);
            PyTuple_SetItem(pArgs, 0, PyString_FromString(imagePath));

            PyObject_CallObject(pFunc, pArgs);
            Py_DECREF(pArgs);
            Py_DECREF(pFunc);
            Py_DECREF(pModule);
        } else {
            PyErr_Print();
            fprintf(stderr, "Failed to load evernote_client\n");
            
        }
        Py_Finalize();
    }
