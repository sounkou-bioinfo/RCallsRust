void R_init_rcallsrustextendrffi_extendr(void *dll);
void register_extendr_panic_hook(void);

void R_init_RCallsRustExtendrFfi(void *dll) {
    register_extendr_panic_hook();
    R_init_rcallsrustextendrffi_extendr(dll);
}
