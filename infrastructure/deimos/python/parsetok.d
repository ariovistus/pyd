/**
  Mirror _parsetok.h
  */
module deimos.python.parsetok;

import core.stdc.stdio;
import deimos.python.node;
import deimos.python.grammar;

extern(C):
// Python-header-file: Include/parsetok.h:

/* Parser-tokenizer link interface */

/// _
struct perrdetail{
    /// _
    int error;
    /// _
    const(char)* filename;
    /// _
    int lineno;
    /// _
    int offset;
    /// _
    char *text;
    /// _
    int token;
    /// _
    int expected;
};

/// _
enum PyPARSE_DONT_IMPLY_DEDENT	= 0x0002;
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    enum PyPARSE_IGNORE_COOKIE = 0x0010;
    /// Availability: 3.*
    enum PyPARSE_BARRY_AS_BDFL = 0x0020;
}

/// _
node* PyParser_ParseString(const(char)*, grammar*, int, perrdetail*);
/// _
node* PyParser_ParseFile (FILE *, const(char)* , grammar *, int,
                                             char*, char*, perrdetail*);

/// _
node* PyParser_ParseStringFlags(const(char)* , grammar*, int,
                                              perrdetail*, int);
version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    node* PyParser_ParseFileFlags(FILE *, const(char)*,
            const(char)*, grammar*, perrdetail*, int);
}else{
    /// Availability: 3.*
    node* PyParser_ParseFileFlags(FILE*, const(char)* , grammar*,
            int, char*, char*, perrdetail*, int);
}

version(Python_3_0_Or_Later) {
    /// Availability: 3.*
    node* PyParser_ParseFileFlagsEx(
            FILE* fp,
            const(char)* filename,
            const(char)* enc,
            grammar* g,
            int start,
            char* ps1,
            char* ps2,
            perrdetail* err_ret,
            int* flags);
}else version(Python_2_6_Or_Later) {
    /// Availability: 2.*
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

/// _
node* PyParser_ParseStringFlagsFilename(const(char)* ,
					      const(char)* ,
					      grammar*, int,
                                              perrdetail*, int);
version(Python_2_6_Or_Later) {
    /// Availability: >= 2.6
    node* PyParser_ParseStringFlagsFilenameEx(
            const(char)* s,
            const(char)* filename,
            grammar* g,
            int start,
            perrdetail* err_ret,
            int* flags);
}

/// _
void PyParser_SetError(perrdetail*);

