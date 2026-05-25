normalize_needle <- function(needle) {
  if (is.raw(needle)) {
    if (length(needle) != 1L) stop("needle must be a scalar raw or integer", call. = FALSE)
    return(as.integer(needle))
  }
  if (!is.numeric(needle) || length(needle) != 1L || is.na(needle) || needle < 0 || needle > 255) {
    stop("needle must be a scalar raw or integer in [0, 255]", call. = FALSE)
  }
  as.integer(needle)
}
check_raw <- function(x) {
  if (!is.raw(x)) stop("x must be a raw vector", call. = FALSE)
  x
}

#' Count byte occurrences
#' @param x A raw vector.
#' @param needle A scalar raw or integer in `[0, 255]`.
#' @return Number of occurrences as a numeric scalar.
#' @export
count_byte <- function(x, needle = as.raw(0x41)) count_byte_ffi(check_raw(x), normalize_needle(needle))

#' Find byte occurrences
#' @inheritParams count_byte
#' @return A data frame with zero-based `position` and integer `byte` columns.
#' @export
find_byte <- function(x, needle = as.raw(0x41)) find_byte_ffi(check_raw(x), normalize_needle(needle))
