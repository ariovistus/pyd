#include <stdio.h>
int foo(int);

// bad bad bad
void *_deh_beg;
void *_deh_end;
void *_tlsstart;
void *_tlsend;

int main() {
    printf("foo(%d)=%d\n", 2, foo(2));
    return 0;
}

