#include <stdio.h>
int foo(int);
int wiz(double);

int main() {
    printf("foo(%d): %d\n", 1, foo(1));
    printf("Success! wiz(%f): %d\n", 1.0, wiz(1.0));
    return 0;
}
