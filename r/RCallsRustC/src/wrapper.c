#include <stdint.h>
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>
#include "rust/api.h"

static uint8_t as_needle(SEXP needle) {
    if (TYPEOF(needle) != INTSXP || XLENGTH(needle) != 1 || INTEGER(needle)[0] == NA_INTEGER || INTEGER(needle)[0] < 0 || INTEGER(needle)[0] > 255) {
        Rf_error("needle must be an integer scalar in [0, 255]");
    }
    return (uint8_t) INTEGER(needle)[0];
}

SEXP RCallsRustC_count_byte(SEXP x, SEXP needle) {
    if (TYPEOF(x) != RAWSXP) Rf_error("x must be a raw vector");
    uint8_t b = as_needle(needle);
    uintptr_t n = (uintptr_t) XLENGTH(x);
    uintptr_t count = rcallsrust_count_byte((const uint8_t *) RAW(x), n, b);
    return Rf_ScalarReal((double) count);
}

SEXP RCallsRustC_find_byte(SEXP x, SEXP needle) {
    if (TYPEOF(x) != RAWSXP) Rf_error("x must be a raw vector");
    uint8_t b = as_needle(needle);
    uintptr_t n = (uintptr_t) XLENGTH(x);
    uintptr_t count = rcallsrust_count_byte((const uint8_t *) RAW(x), n, b);

    SEXP position = PROTECT(Rf_allocVector(REALSXP, (R_xlen_t) count));
    rcallsrust_find_byte_fill((const uint8_t *) RAW(x), n, b, REAL(position));

    SEXP byte = PROTECT(Rf_allocVector(INTSXP, (R_xlen_t) count));
    for (R_xlen_t i = 0; i < (R_xlen_t) count; ++i) INTEGER(byte)[i] = (int) b;

    SEXP out = PROTECT(Rf_allocVector(VECSXP, 2));
    SET_VECTOR_ELT(out, 0, position);
    SET_VECTOR_ELT(out, 1, byte);

    SEXP names = PROTECT(Rf_allocVector(STRSXP, 2));
    SET_STRING_ELT(names, 0, Rf_mkChar("position"));
    SET_STRING_ELT(names, 1, Rf_mkChar("byte"));
    Rf_setAttrib(out, R_NamesSymbol, names);

    SEXP row_names = PROTECT(Rf_allocVector(INTSXP, 2));
    INTEGER(row_names)[0] = NA_INTEGER;
    INTEGER(row_names)[1] = -((int) count);
    Rf_setAttrib(out, R_RowNamesSymbol, row_names);

    SEXP klass = PROTECT(Rf_mkString("data.frame"));
    Rf_setAttrib(out, R_ClassSymbol, klass);

    UNPROTECT(6);
    return out;
}

static const R_CallMethodDef CallEntries[] = {
    {"RCallsRustC_count_byte", (DL_FUNC) &RCallsRustC_count_byte, 2},
    {"RCallsRustC_find_byte", (DL_FUNC) &RCallsRustC_find_byte, 2},
    {NULL, NULL, 0}
};

void R_init_RCallsRustC(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
