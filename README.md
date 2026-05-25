
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
return timings. The quantiles are included because these sub-millisecond
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
| extendr high-level count      |       1e+06 |        500 |          10 | 268.9541 | 271.0066 |  272.7641 | 275.9346 | 278.9222 |  284.9570 |       3655.779 |               0 |      0.000000 |
| extendr_ffi count             |       1e+06 |        500 |          10 | 268.9301 | 271.1431 |  274.0180 | 277.6398 | 317.5747 |  340.8821 |       3596.239 |               0 |      0.000000 |
| savvy count                   |       1e+06 |        500 |          10 | 268.6590 | 274.4132 |  275.8990 | 278.0447 | 282.1359 |  304.9689 |       3618.581 |               0 |      0.000000 |
| C .Call + Rust count          |       1e+06 |        500 |          10 | 273.9950 | 280.6784 |  329.6240 | 344.7632 | 358.0236 |  413.8250 |       3142.662 |               0 |      0.000000 |
| pure C count                  |       1e+06 |        500 |          10 | 216.7390 | 231.1628 |  370.9205 | 419.3695 | 626.0215 |  658.9760 |       2739.439 |               0 |      0.000000 |
| C .Call + Rust data.frame     |       1e+06 |        500 |          10 | 431.1650 | 431.6930 |  433.4804 | 440.5422 | 445.4333 |  533.2980 |       2293.355 |               0 |      0.000000 |
| pure C data.frame             |       1e+06 |        500 |          10 | 435.3640 | 436.8063 |  442.6760 | 557.7519 | 646.9506 | 2725.5799 |       2008.175 |               0 |      4.024398 |
| extendr_ffi data.frame        |       1e+06 |        500 |          10 | 478.5041 | 481.1858 |  484.1066 | 491.7886 | 508.6450 |  554.8050 |       2049.805 |               0 |      0.000000 |
| savvy list + R data.frame     |       1e+06 |        500 |          10 | 481.6600 | 483.0362 |  484.9345 | 488.0437 | 498.5399 |  540.3770 |       2054.311 |               0 |      0.000000 |
| extendr high-level data.frame |       1e+06 |        500 |          10 | 535.4981 | 539.7196 |  543.9636 | 551.4898 | 564.8722 | 2178.8831 |       1829.003 |               0 |      7.345395 |

![](README_files/figure-gfm/benchmark-plot-1.png)<!-- -->

The CSV artifact is written to benchmark-results/r-calls-rust.csv; the
raw `bench::mark()` object used for the plot is written to
benchmark-results/r-calls-rust.rds.

A standalone benchmark report is also available at
[`benchmarks/benchmark.md`](benchmarks/benchmark.md), generated from
[`benchmarks/benchmark.Rmd`](benchmarks/benchmark.Rmd).
