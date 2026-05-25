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
| pure C count                  |       1e+06 |        500 |          10 |    0.000221 |    0.000223 |       0.000265 |    0.000391 |    0.000450 |    0.000663 |       3185.195 |               0 |      0.000000 |
| savvy count                   |       1e+06 |        500 |          10 |    0.000274 |    0.000275 |       0.000278 |    0.000279 |    0.000297 |    0.000331 |       3575.176 |               0 |      0.000000 |
| extendr high-level count      |       1e+06 |        500 |          10 |    0.000275 |    0.000277 |       0.000279 |    0.000283 |    0.000298 |    0.000364 |       3544.772 |               0 |      0.000000 |
| extendr_ffi count             |       1e+06 |        500 |          10 |    0.000274 |    0.000277 |       0.000286 |    0.000339 |    0.000355 |    0.000366 |       3266.047 |               0 |      0.000000 |
| C .Call + Rust count          |       1e+06 |        500 |          10 |    0.000280 |    0.000280 |       0.000287 |    0.000350 |    0.000367 |    0.000686 |       3200.927 |               0 |      0.000000 |
| C .Call + Rust data.frame     |       1e+06 |        500 |          10 |    0.000431 |    0.000433 |       0.000440 |    0.000443 |    0.000464 |    0.000490 |       2266.633 |               0 |      0.000000 |
| pure C data.frame             |       1e+06 |        500 |          10 |    0.000435 |    0.000438 |       0.000461 |    0.000570 |    0.000646 |    0.000699 |       1977.066 |               0 |      0.000000 |
| extendr_ffi data.frame        |       1e+06 |        500 |          10 |    0.000478 |    0.000480 |       0.000482 |    0.000485 |    0.000489 |    0.000499 |       2071.762 |               0 |      0.000000 |
| savvy list + R data.frame     |       1e+06 |        500 |          10 |    0.000482 |    0.000484 |       0.000487 |    0.000494 |    0.000500 |    0.001785 |       2042.820 |               0 |      4.093827 |
| extendr high-level data.frame |       1e+06 |        500 |          10 |    0.000537 |    0.000542 |       0.000544 |    0.000548 |    0.000558 |    0.001961 |       1831.441 |               0 |     18.499400 |

The CSV artifact is written to
/root/RCallsRust/benchmark-results/r-calls-rust.csv.
