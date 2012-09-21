/**
  Mirror _errcode.h

Error codes passed around between file input, tokenizer, parser and
   interpreter.  This is necessary so we can turn them into Python
   exceptions at a higher level.  Note that some errors have a
   slightly different meaning when passed from the tokenizer to the
   parser than when passed from the parser to the interpreter; e.g.
   the parser only returns E_EOF when it hits EOF immediately, and it
   never returns E_OK. */
module deimos.python.errcode;
/** No error */
enum E_OK                   = 10;
/** End Of File */
enum E_EOF                  = 11;
/** Interrupted */
enum E_INTR                 = 12;
/** Bad token */
enum E_TOKEN                = 13;
/** Syntax error */
enum E_SYNTAX               = 14;
/** Ran out of memory */
enum E_NOMEM                = 15;
/** Parsing complete */
enum E_DONE                 = 16;
/** Execution error */
enum E_ERROR                = 17;
/** Inconsistent mixing of tabs and spaces */
enum E_TABSPACE             = 18;
/** Node had too many children */
enum E_OVERFLOW             = 19;
/** Too many indentation levels */
enum E_TOODEEP              = 20;
/** No matching outer block for dedent */
enum E_DEDENT               = 21;
/** Error in decoding into Unicode */
enum E_DECODE               = 22;
/** EOF in triple-quoted string */
enum E_EOFS                 = 23;
/** EOL in single-quoted string */
enum E_EOLS                 = 24;
/** Unexpected characters after a line continuation */
enum E_LINECONT             = 25;
version(Python_3_0_Or_Later) {
    /// Availability: >= 3.0
    enum E_IDENTIFIER           = 26;
}
