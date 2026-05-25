use extendr_api::prelude::*;
use extendr_ffi::{
    cetype_t, R_ClassSymbol, R_NaInt, R_NamesSymbol, R_RowNamesSymbol, Rf_allocVector,
    Rf_mkCharLenCE, Rf_setAttrib, DATAPTR_RO, INTEGER, REAL, SET_STRING_ELT, SET_VECTOR_ELT,
    SEXPTYPE, TYPEOF, XLENGTH,
};
use std::slice;

fn error<T>(message: impl Into<String>) -> extendr_api::Result<T> {
    Err(extendr_api::Error::Other(message.into()))
}

fn raw_slice<'a>(x: &'a Robj) -> extendr_api::Result<&'a [u8]> {
    let sexp = unsafe { x.get() };
    if unsafe { TYPEOF(sexp) } != SEXPTYPE::RAWSXP {
        return error("x must be a raw vector");
    }
    let len = unsafe { XLENGTH(sexp) as usize };
    if len == 0 {
        return Ok(&[]);
    }
    let ptr = unsafe { DATAPTR_RO(sexp) } as *const u8;
    if ptr.is_null() {
        return error("x raw vector has no readable data pointer");
    }
    Ok(unsafe { slice::from_raw_parts(ptr, len) })
}

fn check_needle(needle: i32) -> extendr_api::Result<u8> {
    if !(0..=255).contains(&needle) {
        return error("needle must be in [0, 255]");
    }
    Ok(needle as u8)
}

fn r_char(bytes: &'static [u8]) -> extendr_ffi::SEXP {
    unsafe {
        Rf_mkCharLenCE(
            bytes.as_ptr() as *const _,
            bytes.len() as _,
            cetype_t::CE_UTF8,
        )
    }
}

fn count_positions(bytes: &[u8], needle: u8) -> usize {
    bytes.iter().filter(|&&b| b == needle).count()
}

fn fill_positions(bytes: &[u8], needle: u8, positions: &mut [f64]) {
    let mut j = 0usize;
    for (i, &b) in bytes.iter().enumerate() {
        if b == needle {
            positions[j] = i as f64;
            j += 1;
        }
    }
}

fn data_frame_ffi(positions: &[f64], needle: u8) -> Robj {
    unsafe {
        let n = positions.len();
        let out = Robj::from_sexp(Rf_allocVector(SEXPTYPE::VECSXP, 2));
        let pos = Robj::from_sexp(Rf_allocVector(SEXPTYPE::REALSXP, n as _));
        std::ptr::copy_nonoverlapping(positions.as_ptr(), REAL(pos.get()), n);

        let byte = Robj::from_sexp(Rf_allocVector(SEXPTYPE::INTSXP, n as _));
        for i in 0..n {
            *INTEGER(byte.get()).add(i) = needle as i32;
        }

        SET_VECTOR_ELT(out.get(), 0, pos.get());
        SET_VECTOR_ELT(out.get(), 1, byte.get());

        let names = Robj::from_sexp(Rf_allocVector(SEXPTYPE::STRSXP, 2));
        SET_STRING_ELT(names.get(), 0, r_char(b"position"));
        SET_STRING_ELT(names.get(), 1, r_char(b"byte"));
        Rf_setAttrib(out.get(), R_NamesSymbol, names.get());

        let row_names = Robj::from_sexp(Rf_allocVector(SEXPTYPE::INTSXP, 2));
        *INTEGER(row_names.get()) = R_NaInt;
        *INTEGER(row_names.get()).add(1) = -(n as i32);
        Rf_setAttrib(out.get(), R_RowNamesSymbol, row_names.get());

        let class = Robj::from_sexp(Rf_allocVector(SEXPTYPE::STRSXP, 1));
        SET_STRING_ELT(class.get(), 0, r_char(b"data.frame"));
        Rf_setAttrib(out.get(), R_ClassSymbol, class.get());

        out
    }
}

#[extendr]
fn count_byte_ffi(x: Robj, needle: i32) -> extendr_api::Result<Robj> {
    let bytes = raw_slice(&x)?;
    let needle = check_needle(needle)?;
    let count = count_positions(bytes, needle) as f64;
    Ok(count.into_robj())
}

#[extendr]
fn find_byte_ffi(x: Robj, needle: i32) -> extendr_api::Result<Robj> {
    let bytes = raw_slice(&x)?;
    let needle = check_needle(needle)?;
    let count = count_positions(bytes, needle);
    let mut positions = vec![0.0; count];
    fill_positions(bytes, needle, &mut positions);
    Ok(data_frame_ffi(&positions, needle))
}

extendr_module! {
    mod rcallsrustextendrffi;
    fn count_byte_ffi;
    fn find_byte_ffi;
}
