/**
  Mirror _grammar.h

  Grammar interface
  */
module deimos.python.grammar;

import core.stdc.stdio;

extern(C):
// Python-header-file: Include/object.h:

/** A label of an arc */
struct label{
    /// _
    int		 lb_type;
    /// _
    char*	lb_str;
}

/** Label number 0 is by definition the empty label */
enum EMPTY = 0;

/** A list of labels */
struct labellist{
    /// _
    int		 ll_nlabels;
    /// _
    label*	ll_label;
}

/** An arc from one state to another */
struct arc{
    /** Label of this arc */
    short	a_lbl;
    /** State where this arc goes to */
    short	a_arrow;
}

/** A state in a DFA */
struct state{
    /// _
    int		 s_narcs;
    /** Array of arcs */
    arc*	 s_arc;

    /* Optional accelerators */
    /** Lowest label index */
    int		 s_lower;
    /** Highest label index */
    int		 s_upper;
    /** Accelerator */
    int*	 s_accel;
    /** Nonzero for accepting state */
    int		 s_accept;
}

/** A DFA */
struct dfa{
    /** Non-terminal this represents */
    int		 d_type;
    /** For printing */
    char*	 d_name;
    /** Initial state */
    int		 d_initial;
    /// _
    int		 d_nstates;
    /** Array of states */
    state*	 d_state;
    /// _
    void*/*bitset*/	 d_first;
}

/** A grammar */
struct grammar{
    /// _
    int		 g_ndfas;
    /** Array of DFAs */
    dfa*	 g_dfa;
    /// _
    labellist	 g_ll;
    /** Start symbol of the grammar */
    int		 g_start;
    /** Set if accelerators present */
    int		 g_accel;
}

/* FUNCTIONS */

/// _
grammar* newgrammar(int start);
/// _
dfa* adddfa(grammar* g, int type, char* name);
/// _
int addstate(dfa* d);
/// _
void addarc(dfa* d, int from, int to, int lbl);
/// _
dfa *PyGrammar_FindDFA(grammar* g, int type);

/// _
int addlabel(labellist* ll, int type, char* str);
/// _
int findlabel(labellist* ll, int type, char* str);
/// _
char* PyGrammar_LabelRepr(label* lb);
/// _
void translatelabels(grammar* g);

/// _
void addfirstsets(grammar* g);

/// _
void PyGrammar_AddAccelerators(grammar* g);
/// _
void PyGrammar_RemoveAccelerators(grammar*);

/// _
void printgrammar(grammar* g, FILE* fp);
/// _
void printnonterminals(grammar* g, FILE* fp);

