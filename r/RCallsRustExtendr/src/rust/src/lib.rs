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

#[extendr]
fn count_byte_extendr(x: Raw, needle: i32) -> extendr_api::Result<Robj> {
    let needle = check_needle(needle)?;
    let count = x.as_slice().iter().filter(|&&b| b == needle).count() as f64;
    Ok(count.into_robj())
}

#[extendr]
fn find_byte_extendr(x: Raw, needle: i32) -> extendr_api::Result<Robj> {
    let needle = check_needle(needle)?;
    let positions: Vec<f64> = x
        .as_slice()
        .iter()
        .enumerate()
        .filter_map(|(i, &b)| if b == needle { Some(i as f64) } else { None })
        .collect();
    let byte = vec![needle as i32; positions.len()];
    Ok(data_frame!(position = positions, byte = byte))
}

extendr_module! {
    mod rcallsrustextendr;
    fn count_byte_extendr;
    fn find_byte_extendr;
}
