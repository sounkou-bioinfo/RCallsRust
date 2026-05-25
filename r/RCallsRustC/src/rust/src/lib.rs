use std::slice;

#[no_mangle]
pub extern "C" fn rcallsrust_count_byte(ptr: *const u8, len: usize, needle: u8) -> usize {
    if ptr.is_null() && len != 0 {
        return 0;
    }
    let bytes = unsafe { slice::from_raw_parts(ptr, len) };
    bytes.iter().filter(|&&b| b == needle).count()
}

#[no_mangle]
pub extern "C" fn rcallsrust_find_byte_fill(
    ptr: *const u8,
    len: usize,
    needle: u8,
    positions: *mut f64,
) {
    if (ptr.is_null() && len != 0) || positions.is_null() {
        return;
    }
    let bytes = unsafe { slice::from_raw_parts(ptr, len) };
    let mut j = 0usize;
    for (i, &b) in bytes.iter().enumerate() {
        if b == needle {
            unsafe { *positions.add(j) = i as f64 };
            j += 1;
        }
    }
}
