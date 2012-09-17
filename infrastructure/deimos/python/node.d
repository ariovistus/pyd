module deimos.python.node;

extern(C):
// Python-header-file: Include/node.h
struct node {
    short	n_type;
    char*	n_str;
    int		n_lineno;
    version(Python_2_5_Or_Later){
        int		n_col_offset;
    }
    int		n_nchildren;
    node*	n_child;
}
node* PyNode_New(int type);
int PyNode_AddChild(node* n, int type,
        char* str, int lineno, int col_offset);
void PyNode_Free(node* n);
void PyNode_ListTree(node*);

auto NCH()(node* n) {
    return n.nchildren;
}
auto CHILD()(node* n, size_t i) {
    return n.n_child[i];
}
auto RCHILD()(node* n, size_t i) {
    return CHILD(n, NCH(n)+i);
}
auto TYPE()(node* n) {
    return n.n_type;
}
auto STR()(node* n) {
    return n.n_str;
}
