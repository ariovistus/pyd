/**
 *  Demangle a ".mangleof" name at compile time.
 *
 * Used by meta.Nameof.
 *
 * License:   BSD style: $(LICENSE)
 * Authors:   Don Clugston
 * Copyright: Copyright (C) 2005-2006 Don Clugston
 */
module meta.Demangle;
/*
 Implementation is via pairs of metafunctions:
 a 'demangle' metafunction, which returns a enum string,
 and a 'Consumed' metafunction, which returns an integer, the number of characters which
 are used.
*/
import std.algorithm;

/*****************************************
 * How should the name be displayed?
 */
enum MangledNameType
{
    PrettyName,    // With full type information
    QualifiedName, // No type information, just identifiers seperated by dots
    SymbolName     // Only the ultimate identifier
}

/*****************************************
 * Pretty-prints a mangled type string.
 */
template demangleType(string str, MangledNameType wantQualifiedNames = MangledNameType.PrettyName)
{
    static if (wantQualifiedNames != MangledNameType.PrettyName) {
        // There are only a few types where symbolnameof!(), qualifiednameof!()
        // make sense.
        static if (str[0]=='C' || str[0]=='S' || str[0]=='E' || str[0]=='T')
            enum string demangleType = prettyLname!(str[1..$], wantQualifiedNames);
        else {
            static assert(0, "Demangle error: type '" ~ str ~ "' does not contain a qualified name");
        }
    } else static if (str[0] == 'A') // dynamic array
        enum string demangleType = demangleType!(str[1..$], wantQualifiedNames) ~ "[]";
    else static if (str[0] == 'H')   // associative array
        enum string demangleType
            = demangleType!(str[1+demangleTypeConsumed!(str[1..$])..$], wantQualifiedNames)
            ~ "[" ~ demangleType!(str[1..1+(demangleTypeConsumed!(str[1..$]))], wantQualifiedNames) ~ "]";
    else static if (str[0] == 'G') // static array
        enum string demangleType
            = demangleType!(str[1+countLeadingDigits!(str[1..$])..$], wantQualifiedNames)
            ~ "[" ~ str[1..1+countLeadingDigits!(str[1..$]) ] ~ "]";
    else static if (str[0]=='C')
        enum string demangleType = "class " ~ prettyLname!(str[1..$], wantQualifiedNames);
    else static if (str[0]=='S')
        enum string demangleType = "struct " ~ prettyLname!(str[1..$], wantQualifiedNames);
    else static if (str[0]=='E')
        enum string demangleType = "enum " ~ prettyLname!(str[1..$], wantQualifiedNames);
    else static if (str[0]=='T')
        enum string demangleType = "typedef " ~ prettyLname!(str[1..$], wantQualifiedNames);
    else static if (str[0]=='D' && str.length>2 && isMangledFunction!(( str[1] )) ) // delegate
        enum string demangleType = demangleFunctionOrDelegate!(str[1..$], "delegate ", wantQualifiedNames);
    else static if (str[0]=='P' && str.length>2 && isMangledFunction!(( str[1] )) ) // function pointer
        enum string demangleType = demangleFunctionOrDelegate!(str[1..$], "function ", wantQualifiedNames);
    else static if (str[0]=='P') // only after we've dealt with function pointers
        enum string demangleType = demangleType!(str[1..$], wantQualifiedNames) ~ "*";
    else static if(str[0]=='y'){
        enum string demangleType = "immutable(" ~ demangleType!(str[1..$], wantQualifiedNames) ~ ")";
    }else static if(str[0]=='x'){
        enum string demangleType = "const(" ~ demangleType!(str[1..$], wantQualifiedNames) ~ ")";
    }else static if(str[0]=='O'){
        enum string demangleType = "shared(" ~ demangleType!(str[1..$], wantQualifiedNames) ~ ")";
    }else static if(str.length > 1 && str[0 .. 2]=="Ng"){
        enum string demangleType = "inout(" ~ demangleType!(str[2..$], wantQualifiedNames) ~ ")";
    }else static if (str[0]=='F')
        enum string demangleType = demangleFunctionOrDelegate!(str, "", wantQualifiedNames);
    else static if(str[0] == 'B') {
        static assert(0, "type tuple not handled yet");
    }else enum string demangleType = demangleBasicType!(str);
}

// split these off because they're numerous and simple
// Note: For portability, could replace "v" with void.mangleof, etc.
template demangleBasicType(string str)
{
         static if (str == "v") enum string demangleBasicType = "void";
    else static if (str == "b") enum string demangleBasicType = "bool";
    // possibly a bug in the D name mangling algorithm?
    else static if (str == "x") enum string demangleBasicType = "bool";

    // integral types
    else static if (str == "g") enum string demangleBasicType = "byte";
    else static if (str == "h") enum string demangleBasicType = "ubyte";
    else static if (str == "s") enum string demangleBasicType = "short";
    else static if (str == "t") enum string demangleBasicType = "ushort";
    else static if (str == "i") enum string demangleBasicType = "int";
    else static if (str == "k") enum string demangleBasicType = "uint";
    else static if (str == "l") enum string demangleBasicType = "long";
    else static if (str == "m") enum string demangleBasicType = "ulong";
    // floating point
    else static if (str == "e") enum string demangleBasicType = "real";
    else static if (str == "d") enum string demangleBasicType = "double";
    else static if (str == "f") enum string demangleBasicType = "float";

    else static if (str == "j") enum string demangleBasicType = "ireal";
    else static if (str == "p") enum string demangleBasicType = "idouble";
    else static if (str == "o") enum string demangleBasicType = "ifloat";

    else static if (str == "c") enum string demangleBasicType = "creal";
    else static if (str == "r") enum string demangleBasicType = "cdouble";
    else static if (str == "q") enum string demangleBasicType = "cfloat";
    // Char types
    else static if (str == "a") enum string demangleBasicType = "char";
    else static if (str == "u") enum string demangleBasicType = "wchar";
    else static if (str == "w") enum string demangleBasicType = "dchar";

    else static assert(0, "Demangle Error: '" ~ str ~ "' is not a recognised basic type");
}

template demangleTypeConsumed(string str)
{
    static if (str[0]=='A')
        enum int demangleTypeConsumed = 1 + demangleTypeConsumed!(str[1..$]);
    else static if (str[0]=='H')
        enum int demangleTypeConsumed = 1 + demangleTypeConsumed!(str[1..$])
            + demangleTypeConsumed!(str[1+demangleTypeConsumed!(str[1..$])..$]);
    else static if (str[0]=='G')
        enum int demangleTypeConsumed = 1 + countLeadingDigits!(str[1..$])
            + demangleTypeConsumed!( str[1+countLeadingDigits!(str[1..$])..$] );
    else static if (str.length>2 && (str[0]=='P' || str[0]=='D') && isMangledFunction!(( str[1] )) )
        enum int demangleTypeConsumed = 2 + demangleParamListAndRetValConsumed!(str[2..$]);
    else static if (str[0]=='P') // only after we've dealt with function pointers
        enum int demangleTypeConsumed = 1 + demangleTypeConsumed!(str[1..$]);
    else static if (str[0]=='C' || str[0]=='S' || str[0]=='E' || str[0]=='T')
        enum int demangleTypeConsumed = 1 + getQualifiedNameConsumed!(str[1..$]);
    else static if(str[0] == 'y' && str.length>1) {
        enum int demangleTypeConsumed = 1 + demangleTypeConsumed!(str[1..$]);
    }else static if(str[0] == 'O' && str.length>1) {
        enum int demangleTypeConsumed = 1 + demangleTypeConsumed!(str[1..$]);
    }else static if(str[0] == 'x' && str.length>1) {
        enum int demangleTypeConsumed = 1 + demangleTypeConsumed!(str[1..$]);
    }else static if(str.length>2 && str[0 .. 2] == "Ng" ) {
        enum int demangleTypeConsumed = 2 + demangleTypeConsumed!(str[2..$]);
    }else static if (str[0]=='F' && str.length>1)
        enum int demangleTypeConsumed = 1 + demangleParamListAndRetValConsumed!(str[1..$]);
    else // it's a Basic Type
        enum int demangleTypeConsumed = 1;
}

// --------------------------------------------
//              STATIC ARRAYS

// For static arrays, count number of digits used (eg, return 3 for "674")
template countLeadingDigits(string str)
{
    static if (str.length>0 && beginsWithDigit!( str))
        enum int countLeadingDigits = 1 + countLeadingDigits!( str[1..$]);
    else enum int countLeadingDigits = 0;
}

// --------------------------------------------
//              LNAMES

// str must start with an Lname: first chars give the length
// reads the digits from the front of str, gets the Lname
// Sometimes the characters following the length are also digits!
// (this happens with templates, when the name being 'lengthed' is itself an Lname).
// We guard against this by ensuring that the L is less than the length of the string.
template getLname(string str)
{
    static if (str.length <= 9+1 || !beginsWithDigit!(str[1..$]) )
        enum string getLname = str[1..(str[0]-'0' + 1)];
    else static if (str.length <= 99+2 || !beginsWithDigit!(str[2..$]) )
        enum string getLname = str[2..((str[0]-'0')*10 + str[1]-'0'+ 2)];
    else static if (str.length <= 999+3 || !beginsWithDigit!(str[3..$]) )
        enum string getLname =
            str[3..((str[0]-'0')*100 + (str[1]-'0')*10 + str[2]-'0' + 3)];
    else
        enum string getLname =
            str[4..((str[0]-'0')*1000 + (str[1]-'0')*100 + (str[2]-'0')*10 + (str[3]-'0') + 4)];
}

// Deal with the case where an Lname contains an embedded "__D".
// This can happen when classes, typedefs, etc are declared inside a function.
template pretty_Dname(string str, int dotnameconsumed, MangledNameType wantQualifiedNames)
{
    static if ( isMangledFunction!( (str[2+dotnameconsumed]))) {
        enum string pretty_Dname = pretty_Dfunction!(str, dotnameconsumed,
            demangleParamListAndRetValConsumed!(str[3+dotnameconsumed..$]), wantQualifiedNames);
    } else {
        static if (wantQualifiedNames == MangledNameType.PrettyName) {
            enum string pretty_Dname =
                demangleType!(str[2+dotnameconsumed..$], wantQualifiedNames)
                ~ " " ~ getQualifiedName!(str[2..$], wantQualifiedNames);
        } else {
            enum string pretty_Dname = getQualifiedName!(str[2..$], wantQualifiedNames);
        }
    }
}

// DFunction(_D7testdll3barFiZAya, dotnameconsumed=12, paramlistconsumed=4)

// Deal with the case where an Lname contains an embedded ("__D") function.
// Split into a seperate function because it's so complicated.
template pretty_Dfunction(string str, int dotnameconsumed, int paramlistconsumed,
    MangledNameType wantQualifiedNames)
{
    static if (wantQualifiedNames == MangledNameType.PrettyName) {
        enum string pretty_Dfunction =
            demangleFunctionOrDelegate!(str[2 + dotnameconsumed .. 3 + dotnameconsumed + paramlistconsumed],
                getQualifiedName!(str[2..2+dotnameconsumed], wantQualifiedNames), wantQualifiedNames)
                // BUG: This shouldn't be necessary, the string length is wrong somewhere
            ~ getQualifiedName!(str[3 + dotnameconsumed + paramlistconsumed .. $], wantQualifiedNames, ".");
    } else static if (wantQualifiedNames == MangledNameType.QualifiedName) {
        // Qualified name
        enum string pretty_Dfunction = getQualifiedName!(str[2..2+dotnameconsumed], wantQualifiedNames)
            ~ getQualifiedName!(str[3 + dotnameconsumed + paramlistconsumed .. $], wantQualifiedNames, ".");
    } else { // symbol name
        static if (3 + dotnameconsumed + paramlistconsumed == str.length) {
            enum string pretty_Dfunction = getQualifiedName!(str[2..2+dotnameconsumed], wantQualifiedNames);
        } else {
            enum string pretty_Dfunction = getQualifiedName!(
            str[3 + dotnameconsumed + paramlistconsumed .. $], wantQualifiedNames);
        }
    }
 }

// for an Lname that begins with "_D"
template get_DnameConsumed(string str)
{
    enum int get_DnameConsumed = 2 + getQualifiedNameConsumed!(str[2..$])
        + demangleTypeConsumed!(str[2+getQualifedNameConsumed!(str[2..$])..$]);
}

// If Lname is a template, shows it as a template
template prettyLname(string str, MangledNameType wantQualifiedNames)
{
    static if (str.length>3 && str[0..3] == "__T") // Template instance name
        static if (wantQualifiedNames == MangledNameType.PrettyName) {
            enum string prettyLname =
                prettyLname!(str[3..$], wantQualifiedNames) ~ "!("
                ~ prettyTemplateArgList!(str[3+getQualifiedNameConsumed!(str[3..$])..$], wantQualifiedNames)
                ~ ")";
        } else {
            enum string prettyLname =
                prettyLname!(str[3..$], wantQualifiedNames);
        }
    else static if (str.length>2 && str[0..2] == "_D") {
        enum string prettyLname = pretty_Dname!(str, getQualifiedNameConsumed!(str[2..$]), wantQualifiedNames);
    } else static if ( beginsWithDigit!( str ) )
        enum string prettyLname = getQualifiedName!(str[0..getQualifiedNameConsumed!(str)], wantQualifiedNames);
    else enum string prettyLname = str;
}

// str must start with an lname: first chars give the length
// how many chars are taken up with length digits + the name itself
template getLnameConsumed(string str)
{
    static if (str.length==0)
        enum int getLnameConsumed=0;
    else static if (str.length <= (9+1) || !beginsWithDigit!(str[1..$]) )
        enum int getLnameConsumed = 1 + str[0]-'0';
    else static if (str.length <= (99+2) || !beginsWithDigit!( str[2..$]) )
        enum int getLnameConsumed = (str[0]-'0')*10 + str[1]-'0' + 2;
    else static if (str.length <= (999+3) || !beginsWithDigit!( str[3..$]) )
        enum int getLnameConsumed = (str[0]-'0')*100 + (str[1]-'0')*10 + str[2]-'0' + 3;
    else
        enum int getLnameConsumed = (str[0]-'0')*1000 + (str[1]-'0')*100 + (str[2]-'0')*10 + (str[3]-'0') + 4;
}

template getQualifiedName(string str, MangledNameType wantQualifiedNames, string dotstr = "")
{
    static if (str.length==0) enum string getQualifiedName="";
//    else static if (str.length>2 && str[0]=='_' && str[1]=='D')
//        enum string getDotName = getQualifiedName!(str[2..$], wantQualifiedNames);
    else {
        static assert (beginsWithDigit!(str));
        static if ( getLnameConsumed!(str) < str.length && beginsWithDigit!(str[getLnameConsumed!(str)..$]) ) {
            static if (wantQualifiedNames == MangledNameType.SymbolName) {
                // For symbol names, only display the last symbol
                enum string getQualifiedName =
                    getQualifiedName!(str[getLnameConsumed!(str) .. $], wantQualifiedNames, "");
            } else {
                // Qualified and pretty names display everything
                enum string getQualifiedName = dotstr
                    ~ prettyLname!(getLname!(str), wantQualifiedNames)
                    ~ getQualifiedName!(str[getLnameConsumed!(str) .. $], wantQualifiedNames, ".");
            }
        } else {
            enum string getQualifiedName = dotstr ~ prettyLname!(getLname!(str), wantQualifiedNames);
        }
    }
}

template getQualifiedNameConsumed (string str)
{
    static if ( str.length>1 &&  beginsWithDigit!(str) ) {
        static if (getLnameConsumed!(str) < str.length && beginsWithDigit!( str[getLnameConsumed!(str)..$])) {
            enum int getQualifiedNameConsumed = getLnameConsumed!(str)
                + getQualifiedNameConsumed!(str[getLnameConsumed!(str) .. $]);
        } else {
            enum int getQualifiedNameConsumed = getLnameConsumed!(str);
        }
    } /*else static if (str.length>1 && str[0]=='_' && str[1]=='D') {
        enum int getQualifiedNameConsumed = get_DnameConsumed!(str)
            + getQualifiedNameConsumed!(str[1+get_DnameConsumed!(str)..$]);
    }*/ else static assert(0);
}

// ----------------------------------------
//              FUNCTIONS

/* str[0] must indicate the extern linkage of the function. funcOrDelegStr is the name of the function,
* or "function " or "delegate "
*/
template demangleFunctionOrDelegate(string str, string funcOrDelegStr, MangledNameType wantQualifiedNames)
{
    enum fe = funcAttrsConsumed!(str[1 .. $]);
    enum string funcRest = str[1+fe..$];
    enum e = demangleParamListAndRetValConsumed!(funcRest);
    enum string funcAttrs = demangleFuncAttrs!(str[1 .. 1+fe], wantQualifiedNames);
    enum string demangleFunctionOrDelegate = funcAttrs ~ demangleExtern!(( str[0] ))
        ~ demangleReturnValue!(funcRest, wantQualifiedNames)
        ~ " " ~ funcOrDelegStr ~ "("
        ~ demangleParamList!(funcRest[0..demangleParamListAndRetValConsumed!(funcRest)], wantQualifiedNames)
        ~ ")";
}

template demangleFuncAttrs(string str, MangledNameType wantQualifiedNames) {
    static if(str.startsWith("Na")) {
        enum string demangleFuncAttrs = "pure " ~ demangleFuncAttrs!(str[2..$], wantQualifiedNames);
    }else static if(str.startsWith("Nb")) {
        enum string demangleFuncAttrs = "nothrow " ~ demangleFuncAttrs!(str[2..$], wantQualifiedNames);
    }else static if(str.startsWith("Nc")) {
        enum string demangleFuncAttrs = "ref " ~ demangleFuncAttrs!(str[2..$], wantQualifiedNames);
    }else static if(str.startsWith("Nd")) {
        enum string demangleFuncAttrs = "@property " ~ demangleFuncAttrs!(str[2..$], wantQualifiedNames);
    }else static if(str.startsWith("Ne")) {
        enum string demangleFuncAttrs = "@trusted " ~ demangleFuncAttrs!(str[2..$], wantQualifiedNames);
    }else static if(str.startsWith("Nf")) {
        enum string demangleFuncAttrs = "@safe " ~ demangleFuncAttrs!(str[2..$], wantQualifiedNames);
    }else{
        enum string demangleFuncAttrs = "";
    }
}

template funcAttrsConsumed(string str) {
    static if(str.length > 1 && str[0] == 'N' && 'a' <= str[1] && str[1] <= 'f') {
        enum int funcAttrsConsumed = 2 + funcAttrsConsumed!(str[2..$]);
    }else {
        enum int funcAttrsConsumed = 0;
    }
}

// Special case: types that are in function parameters
// For function parameters, the type can also contain 'lazy', 'out' or 'ref'.
template demangleFunctionParamType(string str, MangledNameType wantQualifiedNames)
{
    static if (str[0]=='L')
        enum string demangleFunctionParamType = "lazy " ~ demangleType!(str[1..$], wantQualifiedNames);
    else static if (str[0]=='K')
        enum string demangleFunctionParamType = "ref " ~ demangleType!(str[1..$], wantQualifiedNames);
    else static if (str[0]=='J')
        enum string demangleFunctionParamType = "out " ~ demangleType!(str[1..$], wantQualifiedNames);
    else enum string demangleFunctionParamType = demangleType!(str, wantQualifiedNames);
}

// Deal with 'out' and 'ref' parameters
template demangleFunctionParamTypeConsumed(string str)
{
    static if (str[0]=='K' || str[0]=='J' || str[0]=='L')
        enum int demangleFunctionParamTypeConsumed = 1 + demangleTypeConsumed!(str[1..$]);
    else enum int demangleFunctionParamTypeConsumed = demangleTypeConsumed!(str);
}

// Return true if c indicates a function. As well as 'F', it can be extern(Pascal), (C), (C++) or (Windows).
template isMangledFunction(char c)
{
    enum bool isMangledFunction = (c=='F' || c=='U' || c=='W' || c=='V' || c=='R');
}

template demangleExtern(char c)
{
    static if (c=='F') enum string demangleExtern = "";
    else static if (c=='U') enum string demangleExtern = "extern (C) ";
    else static if (c=='W') enum string demangleExtern = "extern (Windows) ";
    else static if (c=='V') enum string demangleExtern = "extern (Pascal) ";
    else static if (c=='R') enum string demangleExtern = "extern (C++) ";
    else static assert(0, "Unrecognized extern function.");
}

// Skip through the string until we find the return value. It can either be Z for normal
// functions, or Y for vararg functions.
template demangleReturnValue(string str, MangledNameType wantQualifiedNames)
{
    static assert(str.length>=1, "Demangle error(Function): No return value found");
    static if (str[0]=='Z' || str[0]=='Y' || str[0]=='X')
        enum string demangleReturnValue = demangleType!(str[1..$], wantQualifiedNames);
    else enum string demangleReturnValue = demangleReturnValue!(str[demangleFunctionParamTypeConsumed!(str)..$], wantQualifiedNames);
}

// Stop when we get to the return value
template demangleParamList(string str, MangledNameType wantQualifiedNames, string commastr = "")
{
    static if (str[0] == 'Z')
        enum string demangleParamList = "";
    else static if (str[0] == 'Y')
        enum string demangleParamList = commastr ~ "...";
    else static if (str[0]=='X') // lazy ...
        enum string demangleParamList = commastr ~ "...";
    else
        enum string demangleParamList =  commastr ~
            demangleFunctionParamType!(str[0..demangleFunctionParamTypeConsumed!(str)], wantQualifiedNames)
            ~ demangleParamList!(str[demangleFunctionParamTypeConsumed!(str)..$], wantQualifiedNames, ", ");
}

// How many characters are used in the parameter list and return value
template demangleParamListAndRetValConsumed(string str)
{
    static assert (str.length>0, "Demangle error(ParamList): No return value found");
    static if (str[0]=='Z' || str[0]=='Y' || str[0]=='X')
        enum int demangleParamListAndRetValConsumed = 1 + demangleTypeConsumed!(str[1..$]);
    else {
        enum int demangleParamListAndRetValConsumed = demangleFunctionParamTypeConsumed!(str)
            + demangleParamListAndRetValConsumed!(str[demangleFunctionParamTypeConsumed!(str)..$]);
    }
}

// --------------------------------------------
//              TEMPLATES

template templateValueArgConsumed(string str)
{
    static if (str[0]=='n') enum int templateValueArgConsumed = 1;
    else static if (beginsWithDigit!(str)) enum int templateValueArgConsumed = countLeadingDigits!(str);
    else static if (str[0]=='N') enum int templateValueArgConsumed = 1 + countLeadingDigits!(str[1..$]);
    else static if (str[0]=='e') enum int templateValueArgConsumed = 1 + hexFloatConsumed!(str[1..$]);
    else static if (str[0]=='c') {
        enum int i1 = 1 + hexFloatConsumed!(str[1 .. $]);
        enum int templateValueArgConsumed = i1 + 1 + hexFloatConsumed!(str[i1+1 .. $]);
    }
    else static assert(0, "Unknown character in template value argument");
}

template hexFloatConsumed(string str) {
    static if(str.startsWith("NAN") || str[1 .. $].startsWith("INF")) {
        enum int hexFloatConsumed = 3;
    }else static if(str.startsWith("NINF")) {
        enum int hexFloatConsumed = 4;
    }else{ 
        static if(str.startsWith("N")) {
            enum hx_c = 1;
        }else {
            enum hx_c = 0;
        }
        enum string hxbase = str[hx_c .. $];
        enum hx_c1 = countUntil!("!(std.ascii.isHexDigit(a) && (std.ascii.isDigit(a) || std.ascii.isUpper(a)))")(hxbase);
        static if(hx_c1 < hxbase.length && hxbase[hx_c1] == 'P') {
            enum string hxexp = hxbase[hx_c1+1 .. $];
            static if(hxexp.startsWith("N")) {
                enum hx_c2 = 1;
            }else {
                enum hx_c2 = 0;
            }
            enum string hxexp2 = hxexp[hx_c2 .. $];
            enum hx_c3 = countUntil!("!std.ascii.isDigit(a)")(hxexp2);
            enum int hexFloatConsumed = hx_c + hx_c1 + hx_c2 + hx_c3 + 1;
        }else {
            enum int hexFloatConsumed = hx_c + hx_c1;
        }

    }
}

// pretty-print a template value argument.
template prettyValueArg(string str)
{
    static if (str[0]=='n') enum string prettyValueArg = "null";
    else static if (beginsWithDigit!(str)) enum string prettyValueArg = str;
    else static if ( str[0]=='N') enum string prettyValueArg = "-" ~ str[1..$];
    else static if ( str[0]=='e') enum string prettyValueArg = "0x" ~ str[1..$];
    else static if ( str[0]=='c') {
        enum g = findSplit(str[1 .. $], "c");
        enum string prettyValueArg = "0x" ~ g[0] ~ " + 0x" ~ g[2] ~ "i";
    } else enum string prettyValueArg = "Value arg {" ~ str[0..$] ~ "}";
}

// Pretty-print a template argument
template prettyTemplateArg(string str, MangledNameType wantQualifiedNames)
{
    static if (str[0]=='S') // symbol name
        enum string prettyTemplateArg = prettyLname!(str[1..$], wantQualifiedNames);
    else static if (str[0]=='V') // value
        enum string prettyTemplateArg =
            demangleType!(str[1..1+demangleTypeConsumed!(str[1..$])], wantQualifiedNames)
            ~ " = " ~ prettyValueArg!(str[1+demangleTypeConsumed!(str[1..$])..$]);
    else static if (str[0]=='T') // type
        enum string prettyTemplateArg = demangleType!(str[1..$], wantQualifiedNames);
    else static assert(0, "Unrecognised template argument type: {" ~ str ~ "}");
}

template templateArgConsumed(string str)
{
    static if (str[0]=='S') // symbol name
        enum int templateArgConsumed = 1 + getLnameConsumed!(str[1..$]);
    else static if (str[0]=='V') // value
    {
        enum e = 1 + demangleTypeConsumed!(str[1..$]);
        enum int templateArgConsumed = 1 + demangleTypeConsumed!(str[1..$]) +
            templateValueArgConsumed!(str[1+demangleTypeConsumed!(str[1..$])..$]);
    }
    else static if (str[0]=='T') // type
        enum int templateArgConsumed = 1 + demangleTypeConsumed!(str[1..$]);
    else static assert(0, "Unrecognised template argument type: {" ~ str ~ "}");
}

// Like function parameter lists, template parameter lists also end in a Z,
// but they don't have a return value at the end.
template prettyTemplateArgList(string str, MangledNameType wantQualifiedNames, string commastr="")
{
    static if (str[0]=='Z')
        enum string prettyTemplateArgList = "";
    else
       enum string prettyTemplateArgList = commastr
            ~ prettyTemplateArg!(str[0..templateArgConsumed!(str)], wantQualifiedNames)
            ~ prettyTemplateArgList!(str[templateArgConsumed!(str)..$], wantQualifiedNames, ", ");
}

template templateArgListConsumed(string str)
{
    static assert(str.length>0, "No Z found at end of template argument list");
    static if (str[0]=='Z')
        enum int templateArgListConsumed = 1;
    else
        enum int templateArgListConsumed = templateArgConsumed!(str)
            + templateArgListConsumed!(str[templateArgConsumed!(str)..$]);
}

private {
  /*
   * Return true if the string begins with a decimal digit
   *
   * beginsWithDigit!(s) is equivalent to isdigit!((s[0]));
   * it allows us to avoid the ugly double parentheses.
   */
template beginsWithDigit(string s)
{
  static if (s[0]>='0' && s[0]<='9')
    enum bool beginsWithDigit = true;
  else enum bool beginsWithDigit = false;
}
}



// --------------------------------------------
//              UNIT TESTS

debug(UnitTest){

private {

enum string THISFILE = "meta.Demangle";

ireal SomeFunc(ushort u) { return -3i; }
idouble SomeFunc2(ref ushort u, ubyte w) { return -3i; }
byte[] SomeFunc3(out dchar d, ...) { return null; }
ifloat SomeFunc4(lazy void[] x...) { return 2i; }
char[dchar] SomeFunc5(lazy int delegate()[] z...);

extern (Windows) {
    alias void function (double, long) WinFunc;
}

import core.vararg;
extern (Pascal) {
    alias short[wchar] delegate (bool, ...) PascFunc;
}
extern (C) {
    alias dchar delegate () CFunc;
}
extern (C++) {
    alias cfloat function (wchar) CPPFunc;
}

inout(int) inoutFunc(inout int i) {
    return i+1;
}

int pureFunc(int i) pure {
    return i+1;
}
int purenothrowFunc(int i) pure nothrow {
    return i+1;
}
int trustedFunc(int i) @trusted {
    return i+1;
}
int safeFunc(int i) @safe {
    return i+1;
}
ref int refFunc(int i) {
    return i+1;
}

interface SomeInterface {}

static assert( demangleType!((&SomeFunc).mangleof) == "ireal function (ushort)" );
static assert( demangleType!((&SomeFunc2).mangleof) == "idouble function (ref ushort, ubyte)");
static assert( demangleType!((&SomeFunc3).mangleof) == "byte[] function (out dchar, ...)");
static assert( demangleType!((&SomeFunc4).mangleof) == "ifloat function (lazy void[], ...)");
static assert( demangleType!((&SomeFunc5).mangleof) == "char[dchar] function (lazy int delegate ()[], ...)");
static assert( demangleType!((WinFunc).mangleof)== "extern (Windows) void function (double, long)");
static assert( demangleType!((PascFunc).mangleof) == "extern (Pascal) short[wchar] delegate (bool, ...)");
static assert( demangleType!((CFunc).mangleof) == "extern (C) dchar delegate ()");
static assert( demangleType!((CPPFunc).mangleof) == "extern (C++) cfloat function (wchar)");
static assert(demangleType!((&inoutFunc).mangleof) == "inout(int) function (inout(int))");
static assert(demangleType!((&pureFunc).mangleof) == "pure int function (int)");
static assert(demangleType!((&purenothrowFunc).mangleof) == "pure nothrow int function (int)");
static assert(demangleType!((&trustedFunc).mangleof) == "@trusted int function (int)");
static assert(demangleType!((&safeFunc).mangleof) == "@safe int function (int)");
static assert(demangleType!((&refFunc).mangleof) == "ref int function (int)");
// Interfaces are mangled as classes
static assert( demangleType!(SomeInterface.mangleof) == "class " ~ THISFILE ~ ".SomeInterface");

template ComplexTemplate(real a, creal b)
{
    class ComplexTemplate {}
}

int ComplexFunction(real a, creal b)(int i) {
    return i+1;
}

//static assert( demangleType!((ComplexTemplate!(1.23, 4.56+3.2i)).mangleof) == "class " ~ THISFILE ~ ".ComplexTemplate!(double = 0xa4703d0ad7a3709dff3f, cdouble = 0x85eb51b81e85eb910140c + 0xcdcccccccccccccc0040i).ComplexTemplate");

}
}
