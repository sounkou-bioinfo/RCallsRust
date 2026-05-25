
# RCallsRust

Small reproducible examples for comparing the overhead of R calling Rust
through several package styles. The examples deliberately do **not**
depend on `sassy` or any domain-specific crate.

Each package exposes the same two functions:

- `count_byte(x, needle)`: count occurrences of one byte in a raw
  vector.
- `find_byte(x, needle)`: scan a raw vector and return a `data.frame`
  with zero-based positions and the matched byte.

The Rust kernel is intentionally simple so the examples focus on
interface, input access, and return-object construction overhead.

## Packages

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
|       1e+06 |     65 |               10 |        100 |

| binding                       | input_bytes | iterations | result_size | min_seconds | median_seconds | itr_per_second | mem_alloc_bytes | gc_per_second |
|:------------------------------|------------:|-----------:|------------:|------------:|---------------:|---------------:|----------------:|--------------:|
| savvy list + R data.frame     |       1e+06 |        100 |          10 |    0.000221 |       0.000231 |       4364.665 |               0 |             0 |
| extendr_ffi data.frame        |       1e+06 |        100 |          10 |    0.000230 |       0.000234 |       4253.763 |               0 |             0 |
| savvy count                   |       1e+06 |        100 |          10 |    0.000286 |       0.000290 |       3427.719 |               0 |             0 |
| extendr_ffi count             |       1e+06 |        100 |          10 |    0.000276 |       0.000290 |       3428.015 |               0 |             0 |
| extendr high-level count      |       1e+06 |        100 |          10 |    0.000275 |       0.000290 |       3414.309 |               0 |             0 |
| extendr high-level data.frame |       1e+06 |        100 |          10 |    0.000284 |       0.000292 |       3377.473 |               0 |             0 |
| C .Call + Rust count          |       1e+06 |        100 |          10 |    0.000292 |       0.000295 |       3358.404 |               0 |             0 |
| C .Call + Rust data.frame     |       1e+06 |        100 |          10 |    0.000460 |       0.000463 |       2142.302 |               0 |             0 |

The CSV artifact is written to benchmark-results/r-calls-rust.csv.

A standalone benchmark report is also available at
[`benchmarks/benchmark.md`](benchmarks/benchmark.md), generated from
[`benchmarks/benchmark.Rmd`](benchmarks/benchmark.Rmd).
