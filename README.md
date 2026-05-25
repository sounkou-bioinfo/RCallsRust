
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
# Optional on Linux: RCALLSRUST_BENCH_CPU=0 make report pins the benchmark with taskset.
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
so long-tail outliers do not flatten the main timing bands. On
heterogeneous or frequency-scaled CPUs, unpinned runs can show
core-migration tails; on Linux, set `RCALLSRUST_BENCH_CPU=<cpu>` to pin
the benchmark with `taskset`.

| input_bytes | needle | expected_matches | iterations | cpu_affinity |
|------------:|-------:|-----------------:|-----------:|-------------:|
|       1e+06 |     65 |               10 |        500 |            0 |

| binding                       | input_bytes | iterations | result_size |   min_us |   p25_us | median_us |   p75_us |   p95_us |    max_us | itr_per_second | mem_alloc_bytes | gc_per_second |
|:------------------------------|------------:|-----------:|------------:|---------:|---------:|----------:|---------:|---------:|----------:|---------------:|----------------:|--------------:|
| pure C count                  |       1e+06 |        500 |          10 | 216.4610 | 218.8683 |  231.5645 | 419.0668 | 429.5990 |  449.4131 |       3422.080 |               0 |      0.000000 |
| savvy count                   |       1e+06 |        500 |          10 | 268.6331 | 269.3455 |  271.8525 | 274.0244 | 277.5776 |  288.2330 |       3673.828 |               0 |      0.000000 |
| extendr high-level count      |       1e+06 |        500 |          10 | 268.8779 | 273.9317 |  277.8005 | 338.5370 | 342.2083 |  383.2100 |       3358.517 |               0 |      0.000000 |
| C .Call + Rust count          |       1e+06 |        500 |          10 | 273.6660 | 274.1060 |  280.4721 | 348.6926 | 365.1795 |  401.4010 |       3287.509 |               0 |      0.000000 |
| extendr_ffi count             |       1e+06 |        500 |          10 | 269.7689 | 277.7879 |  321.1505 | 338.4415 | 341.2959 | 4332.8489 |       3007.240 |               0 |      0.000000 |
| pure C data.frame             |       1e+06 |        500 |          10 | 426.2611 | 435.0110 |  442.3365 | 571.3510 | 643.1047 |  665.1041 |       2011.792 |               0 |      0.000000 |
| C .Call + Rust data.frame     |       1e+06 |        500 |          10 | 431.1120 | 441.0743 |  443.5341 | 460.3973 | 471.0585 |  494.1100 |       2227.373 |               0 |      0.000000 |
| extendr_ffi data.frame        |       1e+06 |        500 |          10 | 478.5500 | 480.9421 |  482.6536 | 486.0712 | 494.2625 |  521.5349 |       2064.436 |               0 |      0.000000 |
| savvy list + R data.frame     |       1e+06 |        500 |          10 | 481.7031 | 483.9698 |  485.3721 | 490.0148 | 499.9955 |  527.2730 |       2049.611 |               0 |      0.000000 |
| extendr high-level data.frame |       1e+06 |        500 |          10 | 536.1299 | 540.6938 |  547.1780 | 556.9335 | 584.3325 | 2182.7739 |       1810.507 |               0 |      7.271114 |

![](README_files/figure-gfm/benchmark-plot-1.png)<!-- -->

The CSV artifact is written to benchmark-results/r-calls-rust.csv; the
raw `bench::mark()` object used for the plot is written to
benchmark-results/r-calls-rust.rds.

A standalone benchmark report is also available at
[`benchmarks/benchmark.md`](benchmarks/benchmark.md), generated from
[`benchmarks/benchmark.Rmd`](benchmarks/benchmark.Rmd).
