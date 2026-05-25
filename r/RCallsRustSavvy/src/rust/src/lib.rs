use savvy::{OwnedIntegerSexp, OwnedListSexp, OwnedRealSexp, RawSexp, savvy};

fn check_needle(needle: i32) -> savvy::Result<u8> {
    if !(0..=255).contains(&needle) {
        return Err(savvy::Error::new("needle must be in [0, 255]"));
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

#[savvy]
fn rcallsrust_count_byte_savvy(x: RawSexp, needle: i32) -> savvy::Result<savvy::Sexp> {
    let needle = check_needle(needle)?;
    let count = count_positions(x.as_slice(), needle) as f64;
    count.try_into()
}

#[savvy]
fn rcallsrust_find_byte_savvy(x: RawSexp, needle: i32) -> savvy::Result<savvy::Sexp> {
    let needle = check_needle(needle)?;
    let bytes_slice = x.as_slice();
    let count = count_positions(bytes_slice, needle);
    let mut positions = vec![0.0; count];
    fill_positions(bytes_slice, needle, &mut positions);
    let bytes = vec![needle as i32; positions.len()];

    let mut out = OwnedListSexp::new(2, true)?;
    out.set_name_and_value(0, "position", OwnedRealSexp::try_from_slice(positions)?)?;
    out.set_name_and_value(1, "byte", OwnedIntegerSexp::try_from_slice(bytes)?)?;
    out.into()
}
