RCallsRust benchmark
================

- [Machine](#machine)
- [Results](#results)

This benchmark compares four small R packages that all scan the same raw
vector from Rust and expose the same R API:

- `RCallsRustC`: C `.Call` wrapper plus a Rust static library.
- `RCallsRustExtendrFfi`: `extendr` registration with direct
  `extendr_ffi` use.
- `RCallsRustExtendr`: high-level `extendr` wrapper and `data_frame!`
  output.
- `RCallsRustSavvy`: `savvy` wrappers, returning a named list from Rust
  and converting to a data frame in R.

The benchmark uses the R `bench` package.

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
|       1e+06 |     65 |               10 |        100 |

| binding                       | input_bytes | iterations | result_size | min_seconds | median_seconds | itr_per_second | mem_alloc_bytes | gc_per_second |
|:------------------------------|------------:|-----------:|------------:|------------:|---------------:|---------------:|----------------:|--------------:|
| savvy list + R data.frame     |       1e+06 |        100 |          10 |    0.000230 |       0.000231 |       4324.819 |               0 |       0.00000 |
| extendr_ffi data.frame        |       1e+06 |        100 |          10 |    0.000240 |       0.000245 |       4079.300 |               0 |       0.00000 |
| extendr high-level data.frame |       1e+06 |        100 |          10 |    0.000291 |       0.000300 |       2814.437 |               0 |      28.42865 |
| extendr high-level count      |       1e+06 |        100 |          10 |    0.000331 |       0.000335 |       2962.011 |               0 |       0.00000 |
| savvy count                   |       1e+06 |        100 |          10 |    0.000330 |       0.000337 |       2965.983 |               0 |       0.00000 |
| extendr_ffi count             |       1e+06 |        100 |          10 |    0.000349 |       0.000352 |       2834.373 |               0 |       0.00000 |
| C .Call + Rust count          |       1e+06 |        100 |          10 |    0.000355 |       0.000356 |       2805.356 |               0 |       0.00000 |
| C .Call + Rust data.frame     |       1e+06 |        100 |          10 |    0.000481 |       0.000505 |       1996.106 |               0 |       0.00000 |

The CSV artifact is written to
/root/RCallsRust/benchmark-results/r-calls-rust.csv.
