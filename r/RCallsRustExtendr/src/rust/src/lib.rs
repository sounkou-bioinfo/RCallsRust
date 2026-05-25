use extendr_api::prelude::*;

fn error<T>(message: impl Into<String>) -> extendr_api::Result<T> {
    Err(extendr_api::Error::Other(message.into()))
}

fn check_needle(needle: i32) -> extendr_api::Result<u8> {
    if !(0..=255).contains(&needle) {
        return error("needle must be in [0, 255]");
    }
    Ok(needle as u8)
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

#[extendr]
fn count_byte_extendr(x: Raw, needle: i32) -> extendr_api::Result<Robj> {
    let needle = check_needle(needle)?;
    let count = count_positions(x.as_slice(), needle) as f64;
    Ok(count.into_robj())
}

#[extendr]
fn find_byte_extendr(x: Raw, needle: i32) -> extendr_api::Result<Robj> {
    let needle = check_needle(needle)?;
    let bytes = x.as_slice();
    let count = count_positions(bytes, needle);
    let mut positions = vec![0.0; count];
    fill_positions(bytes, needle, &mut positions);
    let byte = vec![needle as i32; positions.len()];
    Ok(data_frame!(position = positions, byte = byte))
}

extendr_module! {
    mod rcallsrustextendr;
    fn count_byte_extendr;
    fn find_byte_extendr;
}
