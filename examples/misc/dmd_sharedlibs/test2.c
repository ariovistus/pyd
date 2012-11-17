
#include <stdio.h>
int foo(int);
int foo2(int);

// bad bad bad
void *_deh_beg;
void *_deh_end;
__thread void *_tlsstart;
__thread void *_tlsend;

int main() {
    printf("foo(%d)=%d\n", 2, foo(2));
    printf("foo2(%d)=%d\n", 2, foo2(2));
    return 0;
}

