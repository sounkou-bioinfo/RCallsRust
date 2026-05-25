
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
make deps      # install tinytest, bench, and rmarkdown
make install   # install all packages
make test      # run tinytest for all packages
make bench     # run bench::mark benchmark script
make report    # render README.md and benchmarks/benchmark.md
make check     # run R CMD check for all packages
```

## Benchmark results

The benchmark uses the R `bench` package, a deterministic 1 MB raw
vector by default, and reports both scalar count and small-data-frame
return timings.

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

The CSV artifact is written to benchmark-results/r-calls-rust.csv.

A standalone benchmark report is also available at
[`benchmarks/benchmark.md`](benchmarks/benchmark.md), generated from
[`benchmarks/benchmark.Rmd`](benchmarks/benchmark.Rmd).
