module python2.parsetok;

import std.c.stdio;
import python2.node;
import python2.grammar;

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

node* PyParser_ParseString(const(char)*, grammar*, int, perrdetail*);
node* PyParser_ParseFile (FILE *, const(char)* , grammar *, int,
                                             char*, char*, perrdetail*);

node* PyParser_ParseStringFlags(const(char)* , grammar*, int,
                                              perrdetail*, int);
node* PyParser_ParseFileFlags(FILE *, const(char)* , grammar*,
						 int, char*, char*,
						 perrdetail*, int);

node* PyParser_ParseStringFlagsFilename(const(char)* ,
					      const(char)* ,
					      grammar*, int,
                                              perrdetail*, int);

/* Note that he following function is defined in pythonrun.c not parsetok.c. */
void PyParser_SetError(perrdetail*);

