use savvy::{savvy, OwnedIntegerSexp, OwnedListSexp, OwnedRealSexp, RawSexp};

fn check_needle(needle: i32) -> savvy::Result<u8> {
    if !(0..=255).contains(&needle) {
        return Err(savvy::Error::new("needle must be in [0, 255]"));
    }
    Ok(needle as u8)
}

#[savvy]
fn rcallsrust_count_byte_savvy(x: RawSexp, needle: i32) -> savvy::Result<savvy::Sexp> {
    let needle = check_needle(needle)?;
    let count = x.iter().filter(|&b| *b == needle).count() as f64;
    count.try_into()
}

#[savvy]
fn rcallsrust_find_byte_savvy(x: RawSexp, needle: i32) -> savvy::Result<savvy::Sexp> {
    let needle = check_needle(needle)?;
    let positions: Vec<f64> = x
        .iter()
        .enumerate()
        .filter_map(|(i, b)| if *b == needle { Some(i as f64) } else { None })
        .collect();
    let bytes = vec![needle as i32; positions.len()];

    let mut out = OwnedListSexp::new(2, true)?;
    out.set_name_and_value(0, "position", OwnedRealSexp::try_from_slice(positions)?)?;
    out.set_name_and_value(1, "byte", OwnedIntegerSexp::try_from_slice(bytes)?)?;
    out.into()
}
