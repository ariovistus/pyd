module deimos.python.parsetok;

import std.c.stdio;
import deimos.python.node;
import deimos.python.grammar;

extern(C):
// Python-header-file: Include/parsetok.h:

/* Parser-tokenizer link interface */

struct perrdetail{
    int error;
    const(char)* filename;
    int lineno;
    int offset;
    char *text;
    int token;
    int expected;
};

enum PyPARSE_DONT_IMPLY_DEDENT	= 0x0002;
version(Python_3_0_Or_Later) {
    enum PyPARSE_IGNORE_COOKIE = 0x0010;
    enum PyPARSE_BARRY_AS_BDFL = 0x0020;
}

node* PyParser_ParseString(const(char)*, grammar*, int, perrdetail*);
node* PyParser_ParseFile (FILE *, const(char)* , grammar *, int,
                                             char*, char*, perrdetail*);

node* PyParser_ParseStringFlags(const(char)* , grammar*, int,
                                              perrdetail*, int);
version(Python_3_0_Or_Later) {
    node* PyParser_ParseFileFlags(FILE *, const(char)*,
            const(char)*, grammar*, perrdetail*, int);
}else{
    node* PyParser_ParseFileFlags(FILE*, const(char)* , grammar*,
            int, char*, char*, perrdetail*, int);
}

version(Python_3_0_Or_Later) {
    node* PyParser_ParseFileFlagsEx(
            FILE* fp,
            const(char)* filename,       /* decoded from the filesystem encoding */
            const(char)* enc,
            grammar* g,
            int start,
            char* ps1,
            char* ps2,
            perrdetail* err_ret,
            int* flags);
}else version(Python_2_6_Or_Later) {
    node* PyParser_ParseFileFlagsEx(
            FILE* fp, 
            const(char)* filename, 
            grammar* g,
            int start, 
            char* ps1, 
            char* ps2,
            perrdetail* err_ret, 
            int* flags);
}

node* PyParser_ParseStringFlagsFilename(const(char)* ,
					      const(char)* ,
					      grammar*, int,
                                              perrdetail*, int);
version(Python_2_6_Or_Later) {
    node* PyParser_ParseStringFlagsFilenameEx(
    const(char)* s,
    const(char)* filename,       
    grammar* g,
    int start,
    perrdetail* err_ret,
    int* flags);
}

/* Note that he following function is defined in pythonrun.c not parsetok.c. */
void PyParser_SetError(perrdetail*);

