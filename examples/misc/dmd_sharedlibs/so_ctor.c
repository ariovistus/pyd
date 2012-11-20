void my_init();
void my_fini();

__attribute__((__constructor__)) void actual_init() {
    my_init();
}

