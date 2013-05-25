void hacky_init();
void hacky_fini();

__attribute__((__constructor__)) void actual_init() {
    hacky_init();
}
__attribute__((__destructor__)) void actual_fini() {
    hacky_fini();
}

