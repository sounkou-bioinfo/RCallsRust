#include <stdint.h>
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

static uint8_t as_needle(SEXP needle) {
    if (TYPEOF(needle) != INTSXP || XLENGTH(needle) != 1 || INTEGER(needle)[0] == NA_INTEGER || INTEGER(needle)[0] < 0 || INTEGER(needle)[0] > 255) {
        Rf_error("needle must be an integer scalar in [0, 255]");
    }
    return (uint8_t) INTEGER(needle)[0];
}

static R_xlen_t count_byte_c(const uint8_t *ptr, R_xlen_t len, uint8_t needle) {
    R_xlen_t count = 0;
    for (R_xlen_t i = 0; i < len; ++i) {
        count += ptr[i] == needle;
    }
    return count;
}

static void fill_positions_c(const uint8_t *ptr, R_xlen_t len, uint8_t needle, double *positions) {
    R_xlen_t j = 0;
    for (R_xlen_t i = 0; i < len; ++i) {
        if (ptr[i] == needle) positions[j++] = (double) i;
    }
}

SEXP RCallsC_count_byte(SEXP x, SEXP needle) {
    if (TYPEOF(x) != RAWSXP) Rf_error("x must be a raw vector");
    uint8_t b = as_needle(needle);
    R_xlen_t n = XLENGTH(x);
    R_xlen_t count = count_byte_c((const uint8_t *) RAW(x), n, b);
    return Rf_ScalarReal((double) count);
}

SEXP RCallsC_find_byte(SEXP x, SEXP needle) {
    if (TYPEOF(x) != RAWSXP) Rf_error("x must be a raw vector");
    uint8_t b = as_needle(needle);
    R_xlen_t n = XLENGTH(x);
    R_xlen_t count = count_byte_c((const uint8_t *) RAW(x), n, b);

    SEXP position = PROTECT(Rf_allocVector(REALSXP, count));
    fill_positions_c((const uint8_t *) RAW(x), n, b, REAL(position));

    SEXP byte = PROTECT(Rf_allocVector(INTSXP, count));
    for (R_xlen_t i = 0; i < count; ++i) INTEGER(byte)[i] = (int) b;

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
    {"RCallsC_count_byte", (DL_FUNC) &RCallsC_count_byte, 2},
    {"RCallsC_find_byte", (DL_FUNC) &RCallsC_find_byte, 2},
    {NULL, NULL, 0}
};

void R_init_RCallsC(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
