RCallsRust benchmark
================

- [Machine](#machine)
- [Results](#results)
- [Plot](#plot)

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
output, then fill positions. Quantiles are reported because these
sub-millisecond scans can have visible scheduler/cache tails;
`itr_per_second` is bench’s aggregate throughput and is not simply
`1 / median_seconds`.

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

| binding                       | input_bytes | iterations | result_size | min_seconds | p25_seconds | median_seconds | p75_seconds | p95_seconds | max_seconds | itr_per_second | mem_alloc_bytes | gc_per_second |
|:------------------------------|------------:|-----------:|------------:|------------:|------------:|---------------:|------------:|------------:|------------:|---------------:|----------------:|--------------:|
| pure C count                  |       1e+06 |        500 |          10 |    0.000221 |    0.000223 |       0.000260 |    0.000416 |    0.000447 |    0.000644 |       3236.748 |               0 |       0.00000 |
| savvy count                   |       1e+06 |        500 |          10 |    0.000274 |    0.000276 |       0.000277 |    0.000278 |    0.000290 |    0.000309 |       3591.362 |               0 |       0.00000 |
| extendr high-level count      |       1e+06 |        500 |          10 |    0.000274 |    0.000276 |       0.000278 |    0.000282 |    0.000293 |    0.000314 |       3570.262 |               0 |       0.00000 |
| extendr_ffi count             |       1e+06 |        500 |          10 |    0.000269 |    0.000277 |       0.000281 |    0.000339 |    0.000355 |    0.000490 |       3290.933 |               0 |       0.00000 |
| C .Call + Rust count          |       1e+06 |        500 |          10 |    0.000279 |    0.000301 |       0.000382 |    0.000398 |    0.000409 |    0.000443 |       2787.818 |               0 |       0.00000 |
| C .Call + Rust data.frame     |       1e+06 |        500 |          10 |    0.000431 |    0.000431 |       0.000438 |    0.000443 |    0.000462 |    0.000493 |       2268.434 |               0 |       0.00000 |
| extendr_ffi data.frame        |       1e+06 |        500 |          10 |    0.000478 |    0.000481 |       0.000484 |    0.000491 |    0.000501 |    0.000542 |       2054.499 |               0 |       0.00000 |
| savvy list + R data.frame     |       1e+06 |        500 |          10 |    0.000482 |    0.000484 |       0.000485 |    0.000489 |    0.000500 |    0.000536 |       2049.656 |               0 |       0.00000 |
| pure C data.frame             |       1e+06 |        500 |          10 |    0.000435 |    0.000442 |       0.000494 |    0.000629 |    0.000654 |    0.000698 |       1904.205 |               0 |       0.00000 |
| extendr high-level data.frame |       1e+06 |        500 |          10 |    0.000534 |    0.000538 |       0.000541 |    0.000552 |    0.000577 |    0.002862 |       1826.821 |               0 |       7.33663 |

## Plot

![](benchmark_files/figure-gfm/benchmark-plot-1.png)<!-- -->

The CSV artifact is written to
/root/RCallsRust/benchmark-results/r-calls-rust.csv; the raw
`bench::mark()` object used for the plot is written to
/root/RCallsRust/benchmark-results/r-calls-rust.rds.
