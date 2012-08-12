#include <stdio.h>
int foo(int);

int main() {
    printf("foo(%d)=%d\n", 2, foo(2));
    return 0;
}

