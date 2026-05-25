
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
make check     # run R CMD check for all packages
```

## Benchmark results

The benchmark uses the R `bench` package, a deterministic 1 MB raw
vector by default, and reports both scalar count and small-data-frame
return timings. The quantiles are included because these sub-millisecond
scans can have visible scheduler/cache tails. Timing columns are
reported in microseconds; `itr_per_second` is bench’s aggregate
throughput and is not simply `1e6 / median_us`. The distribution plot
uses a log10 microsecond scale so long-tail outliers do not flatten the
main timing bands.

| input_bytes | needle | expected_matches | iterations |
|------------:|-------:|-----------------:|-----------:|
|       1e+06 |     65 |               10 |        500 |

| binding                       | input_bytes | iterations | result_size |   min_us |   p25_us | median_us |   p75_us |   p95_us |    max_us | itr_per_second | mem_alloc_bytes | gc_per_second |
|:------------------------------|------------:|-----------:|------------:|---------:|---------:|----------:|---------:|---------:|----------:|---------------:|----------------:|--------------:|
| savvy count                   |       1e+06 |        500 |          10 | 274.0360 | 274.7902 |  277.2285 | 277.8410 | 292.3605 |  320.3610 |       3597.251 |               0 |       0.00000 |
| extendr_ffi count             |       1e+06 |        500 |          10 | 274.3209 | 276.8912 |  278.8425 | 289.1962 | 293.2529 |  303.4170 |       3544.514 |               0 |       0.00000 |
| extendr high-level count      |       1e+06 |        500 |          10 | 270.2069 | 276.9167 |  279.7499 | 286.3247 | 295.5162 |  313.4590 |       3546.586 |               0 |       0.00000 |
| C .Call + Rust count          |       1e+06 |        500 |          10 | 279.5591 | 288.6943 |  348.4925 | 361.5808 | 368.0456 |  439.6000 |       3037.350 |               0 |       0.00000 |
| pure C count                  |       1e+06 |        500 |          10 | 221.2031 | 236.7363 |  388.2621 | 443.3598 | 666.4246 |  695.8020 |       2632.649 |               0 |       0.00000 |
| C .Call + Rust data.frame     |       1e+06 |        500 |          10 | 430.6680 | 431.0012 |  432.5770 | 439.0988 | 448.2542 |  471.7840 |       2295.732 |               0 |       0.00000 |
| pure C data.frame             |       1e+06 |        500 |          10 | 434.9441 | 437.9911 |  461.2416 | 631.6440 | 647.3065 |  691.5161 |       1951.640 |               0 |       0.00000 |
| extendr_ffi data.frame        |       1e+06 |        500 |          10 | 478.0450 | 480.0525 |  481.7810 | 484.1247 | 493.4375 |  521.4739 |       2069.295 |               0 |       0.00000 |
| savvy list + R data.frame     |       1e+06 |        500 |          10 | 481.5630 | 484.0010 |  485.6825 | 488.8707 | 496.8615 |  514.2461 |       2052.321 |               0 |       0.00000 |
| extendr high-level data.frame |       1e+06 |        500 |          10 | 534.7910 | 539.8541 |  544.5181 | 553.6925 | 575.5297 | 2905.7070 |       1822.088 |               0 |      10.99852 |

![](README_files/figure-gfm/benchmark-plot-1.png)<!-- -->

The CSV artifact is written to benchmark-results/r-calls-rust.csv; the
raw `bench::mark()` object used for the plot is written to
benchmark-results/r-calls-rust.rds.

A standalone benchmark report is also available at
[`benchmarks/benchmark.md`](benchmarks/benchmark.md), generated from
[`benchmarks/benchmark.Rmd`](benchmarks/benchmark.Rmd).
