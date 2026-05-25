
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
return timings. The quantiles are included because these sub-millisecond
scans can have visible scheduler/cache tails; `itr_per_second` is
bench’s aggregate throughput and is not simply `1 / median_seconds`.

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

The CSV artifact is written to benchmark-results/r-calls-rust.csv.

A standalone benchmark report is also available at
[`benchmarks/benchmark.md`](benchmarks/benchmark.md), generated from
[`benchmarks/benchmark.Rmd`](benchmarks/benchmark.Rmd).
