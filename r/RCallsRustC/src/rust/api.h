#ifndef RCALLSRUSTC_RUST_API_H
#define RCALLSRUSTC_RUST_API_H

#include <stdint.h>
#include <stddef.h>

uintptr_t rcallsrust_count_byte(const uint8_t *ptr, uintptr_t len, uint8_t needle);
void rcallsrust_find_byte_fill(const uint8_t *ptr, uintptr_t len, uint8_t needle, double *positions);

#endif
