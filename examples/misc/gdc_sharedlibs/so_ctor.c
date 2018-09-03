#include <stdio.h>
void my_init();
void my_fini();

__attribute__((__constructor__)) void actual_init() {
    printf("initing\n");
    my_init();
}
__attribute__((__destructor__)) void actual_fini() {
    printf("dniting\n");
    my_fini();
}

