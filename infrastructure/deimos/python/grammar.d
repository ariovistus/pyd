module deimos.python.grammar;

import std.c.stdio;

extern(C):
// Python-header-file: Include/object.h:

/* A label of an arc */

struct label{
    int		 lb_type;
    char*	lb_str;
}

enum EMPTY = 0;		/* Label number 0 is by definition the empty label */

/* A list of labels */

struct labellist{
    int		 ll_nlabels;
    label*	ll_label;
}

/* An arc from one state to another */

struct arc{
    short	a_lbl;		/* Label of this arc */
    short	a_arrow;	/* State where this arc goes to */
}

/* A state in a DFA */

struct state{
    int		 s_narcs;
    arc*	 s_arc;		/* Array of arcs */
	
    /* Optional accelerators */
    int		 s_lower;	/* Lowest label index */
    int		 s_upper;	/* Highest label index */
    int*	 s_accel;	/* Accelerator */
    int		 s_accept;	/* Nonzero for accepting state */
}

/* A DFA */

struct dfa{
    int		 d_type;	/* Non-terminal this represents */
    char*	 d_name;	/* For printing */
    int		 d_initial;	/* Initial state */
    int		 d_nstates;
    state*	 d_state;	/* Array of states */
    void*/*bitset*/	 d_first;
} 

/* A grammar */

struct grammar{
    int		 g_ndfas;
    dfa*	 g_dfa;		/* Array of DFAs */
    labellist	 g_ll;
    int		 g_start;	/* Start symbol of the grammar */
    int		 g_accel;	/* Set if accelerators present */
} 

/* FUNCTIONS */

grammar* newgrammar(int start);
dfa* adddfa(grammar* g, int type, char* name);
int addstate(dfa* d);
void addarc(dfa* d, int from, int to, int lbl);
dfa *PyGrammar_FindDFA(grammar* g, int type);

int addlabel(labellist* ll, int type, char* str);
int findlabel(labellist* ll, int type, char* str);
char* PyGrammar_LabelRepr(label* lb);
void translatelabels(grammar* g);

void addfirstsets(grammar* g);

void PyGrammar_AddAccelerators(grammar* g);
void PyGrammar_RemoveAccelerators(grammar*);

void printgrammar(grammar* g, FILE* fp);
void printnonterminals(grammar* g, FILE* fp);

