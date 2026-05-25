
# RCallsRust

Small reproducible examples for comparing the overhead of R calling Rust
through several package styles. The examples deliberately do **not**
depend on `sassy` or any domain-specific crate. A pure C package is
included as a baseline.

Each package exposes the same two functions:

- `count_byte(x, needle)`: count occurrences of one byte in a raw
  vector.
- `find_byte(x, needle)`: scan a raw vector and return a `data.frame`
  with zero-based positions and the matched byte.

The Rust kernel is intentionally simple so the examples focus on
interface, input access, and return-object construction overhead.

## Packages

- [`r/RCallsC`](r/RCallsC): pure C `.Call` implementation using R’s
  native C API.
- [`r/RCallsRustC`](r/RCallsRustC): old-school `.Call` C wrapper plus a
  Rust `staticlib`, following the structure of
  [`r-rust/hellorust`](https://github.com/r-rust/hellorust).
- [`r/RCallsRustExtendrFfi`](r/RCallsRustExtendrFfi): an `extendr`
  package that uses `extendr_ffi` directly for raw-vector access and
  data-frame construction. R wrappers are generated from `extendr`
  metadata.
- [`r/RCallsRustExtendr`](r/RCallsRustExtendr): a high-level `extendr`
  package using `Raw` and `data_frame!`. R wrappers are generated from
  `extendr` metadata.
- [`r/RCallsRustSavvy`](r/RCallsRustSavvy): a
  [`savvy`](https://github.com/yutannihilation/savvy) package variant.
  Its C/R wrappers are generated with `savvy::savvy_update()`. It
  returns a named list from Rust and constructs the final `data.frame`
  in R, which matches savvy’s documented recommendation for data frames.

All `find_byte()` implementations use the same two-pass algorithm: first
count matches to determine output size, then scan again to fill
positions. This keeps the Rust-backed variants algorithmically aligned
with the C/R API variants, which need the output size before allocating
R vectors.

## Make targets

From the repository root:

``` sh
make deps      # install tinytest, bench, ggplot2, and rmarkdown
make install   # install all packages
make test      # run tinytest for all packages
make bench     # run bench::mark benchmark script
make report    # render README.md and benchmarks/benchmark.md
# Linux benchmarks pin to one CPU by default; use RCALLSRUST_BENCH_CPU=none to disable.
# Use RCALLSRUST_BENCH_CPU=<cpu> to choose a specific CPU.
make check     # run R CMD check for all packages
```

## Benchmark results

The benchmark uses the R `bench` package, a deterministic 1 MB raw
vector by default, and reports both scalar count and small-data-frame
return timings. The C translation units are compiled with
`-O3 -ftree-vectorize`, and R wrappers use explicit `PACKAGE = "..."`
native lookups. The quantiles are included because these sub-millisecond
scans can have visible scheduler/cache tails. Each case is measured in a
separate `bench::mark()` run to reduce cross-case cache and allocation
interference. Timing columns are reported in microseconds;
`itr_per_second` is bench’s aggregate throughput and is not simply
`1e6 / median_us`. The distribution plot uses a log10 microsecond scale
so long-tail outliers do not flatten the main timing bands. On Linux,
benchmark runs pin themselves to one CPU by default
(`RCALLSRUST_BENCH_CPU=auto`) to avoid core-migration tails on
heterogeneous or frequency-scaled CPUs. Set `RCALLSRUST_BENCH_CPU=<cpu>`
to choose a CPU, or `RCALLSRUST_BENCH_CPU=none` to disable pinning.

| input_bytes | needle | expected_matches | iterations | cpu_affinity |
|------------:|-------:|-----------------:|-----------:|:-------------|
|       1e+06 |     65 |               10 |        500 | auto:0       |

| binding                       | input_bytes | iterations | result_size |   min_us |   p25_us | median_us |   p75_us |   p95_us |    max_us | itr_per_second | mem_alloc_bytes | gc_per_second |
|:------------------------------|------------:|-----------:|------------:|---------:|---------:|----------:|---------:|---------:|----------:|---------------:|----------------:|--------------:|
| pure C count                  |       1e+06 |        500 |          10 | 112.8591 | 121.7765 |  153.0970 | 153.6648 | 160.4780 |  162.7341 |       7006.881 |               0 |      0.000000 |
| extendr_ffi count             |       1e+06 |        500 |          10 | 269.1790 | 271.3408 |  272.5621 | 275.5001 | 279.9320 |  308.7170 |       3654.424 |               0 |      0.000000 |
| savvy count                   |       1e+06 |        500 |          10 | 268.9509 | 271.9640 |  272.6684 | 276.3022 | 280.7519 |  321.3820 |       3646.167 |               0 |      0.000000 |
| extendr high-level count      |       1e+06 |        500 |          10 | 269.3119 | 272.6929 |  275.6294 | 277.8616 | 283.2437 |  327.8069 |       3623.637 |               0 |      0.000000 |
| pure C data.frame             |       1e+06 |        500 |          10 | 326.8120 | 330.8023 |  331.6280 | 333.8901 | 341.9978 | 2640.3400 |       2994.247 |               0 |      6.000495 |
| C .Call + Rust count          |       1e+06 |        500 |          10 | 274.1070 | 281.2407 |  337.8839 | 347.9552 | 360.8749 |  389.8530 |       3109.289 |               0 |      0.000000 |
| C .Call + Rust data.frame     |       1e+06 |        500 |          10 | 431.2620 | 438.9913 |  442.8221 | 460.7965 | 470.8609 |  498.2511 |       2229.847 |               0 |      0.000000 |
| extendr_ffi data.frame        |       1e+06 |        500 |          10 | 478.5442 | 481.9244 |  483.6406 | 487.6528 | 502.8841 |  521.5640 |       2056.804 |               0 |      0.000000 |
| savvy list + R data.frame     |       1e+06 |        500 |          10 | 482.0980 | 485.0553 |  485.9956 | 488.3560 | 500.2218 |  543.1140 |       2048.217 |               0 |      0.000000 |
| extendr high-level data.frame |       1e+06 |        500 |          10 | 536.7920 | 541.9107 |  547.8245 | 556.0437 | 575.2578 | 2196.9929 |       1814.941 |               0 |      7.288920 |

![](README_files/figure-gfm/benchmark-plot-1.png)<!-- -->

The CSV artifact is written to benchmark-results/r-calls-rust.csv; the
raw `bench::mark()` object used for the plot is written to
benchmark-results/r-calls-rust.rds.

A standalone benchmark report is also available at
[`benchmarks/benchmark.md`](benchmarks/benchmark.md), generated from
[`benchmarks/benchmark.Rmd`](benchmarks/benchmark.Rmd).
