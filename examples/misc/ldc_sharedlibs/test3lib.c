typedef struct {
    int i;
    int j;
    double d;
} Foobar; 

Foobar foo;

__attribute__((__constructor__)) void foo_init() {
    foo.i = 1;
    foo.j = 2;
    foo.d = 3.4;
}
