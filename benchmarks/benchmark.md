RCallsRust benchmark
================

- [Machine](#machine)
- [Results](#results)

This benchmark compares five small R packages that all scan the same raw
vector and expose the same R API:

- `RCallsC`: pure C `.Call` implementation.
- `RCallsRustC`: C `.Call` wrapper plus a Rust static library.
- `RCallsRustExtendrFfi`: `extendr` registration with direct
  `extendr_ffi` use.
- `RCallsRustExtendr`: high-level `extendr` wrapper and `data_frame!`
  output.
- `RCallsRustSavvy`: `savvy` wrappers, returning a named list from Rust
  and converting to a data frame in R.

The benchmark uses the R `bench` package. All `find_byte()`
implementations use the same two-pass algorithm: count matches, allocate
output, then fill positions.

## Machine

| field    | value                               |
|:---------|:------------------------------------|
| system   | Linux                               |
| release  | 6.8.0-78-generic                    |
| machine  | x86_64                              |
| R        | R version 4.6.0 (2026-04-24)        |
| platform | x86_64-pc-linux-gnu                 |
| cargo    | cargo 1.91.1 (ea2d97820 2025-10-10) |
| rustc    | rustc 1.91.1 (ed61e7d7e 2025-11-07) |

## Results

| input_bytes | needle | expected_matches | iterations |
|------------:|-------:|-----------------:|-----------:|
|       1e+06 |     65 |               10 |        500 |

| binding                       | input_bytes | iterations | result_size | min_seconds | median_seconds | itr_per_second | mem_alloc_bytes | gc_per_second |
|:------------------------------|------------:|-----------:|------------:|------------:|---------------:|---------------:|----------------:|--------------:|
| pure C count                  |       1e+06 |        500 |          10 |    0.000221 |       0.000234 |       3694.587 |               0 |      0.000000 |
| extendr high-level count      |       1e+06 |        500 |          10 |    0.000269 |       0.000275 |       3594.896 |               0 |      0.000000 |
| C .Call + Rust count          |       1e+06 |        500 |          10 |    0.000279 |       0.000281 |       3523.554 |               0 |      0.000000 |
| extendr_ffi count             |       1e+06 |        500 |          10 |    0.000274 |       0.000289 |       3453.247 |               0 |      6.920335 |
| savvy count                   |       1e+06 |        500 |          10 |    0.000269 |       0.000324 |       3199.951 |               0 |      0.000000 |
| C .Call + Rust data.frame     |       1e+06 |        500 |          10 |    0.000431 |       0.000433 |       2294.671 |               0 |      0.000000 |
| savvy list + R data.frame     |       1e+06 |        500 |          10 |    0.000481 |       0.000489 |       2033.336 |               0 |      4.074822 |
| extendr_ffi data.frame        |       1e+06 |        500 |          10 |    0.000489 |       0.000493 |       2026.243 |               0 |      0.000000 |
| pure C data.frame             |       1e+06 |        500 |          10 |    0.000426 |       0.000550 |       1724.241 |               0 |      0.000000 |
| extendr high-level data.frame |       1e+06 |        500 |          10 |    0.000535 |       0.000554 |       1805.448 |               0 |     18.236851 |

The CSV artifact is written to
/root/RCallsRust/benchmark-results/r-calls-rust.csv.
