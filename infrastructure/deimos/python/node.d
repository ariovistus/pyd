/**
  Mirror _node.h

  Parse tree node interface
  */
module deimos.python.node;

extern(C):
// Python-header-file: Include/node.h
/// _
struct node {
    /// _
    short	n_type;
    /// _
    char*	n_str;
    /// _
    int		n_lineno;
    version(Python_2_5_Or_Later){
        /// Availability: >= 2.5
        int		n_col_offset;
    }
    /// _
    int		n_nchildren;
    /// _
    node*	n_child;
}
/// _
node* PyNode_New(int type);
/// _
int PyNode_AddChild(node* n, int type,
        char* str, int lineno, int col_offset);
/// _
void PyNode_Free(node* n);
/// _
void PyNode_ListTree(node*);

/** Node access functions */
auto NCH()(node* n) {
    return n.nchildren;
}
/// _
auto CHILD()(node* n, size_t i) {
    return n.n_child[i];
}
/// _
auto RCHILD()(node* n, size_t i) {
    return CHILD(n, NCH(n)+i);
}
/// _
auto TYPE()(node* n) {
    return n.n_type;
}
/// _
auto STR()(node* n) {
    return n.n_str;
}
