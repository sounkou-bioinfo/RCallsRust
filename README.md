# RCallsRust

Small reproducible examples for comparing the overhead of R calling Rust through
several package styles. The examples deliberately do **not** depend on `sassy` or
any domain-specific crate.

Each package exposes the same two functions:

- `count_byte(x, needle)`: count occurrences of one byte in a raw vector.
- `find_byte(x, needle)`: scan a raw vector and return a `data.frame` with
  zero-based positions and the matched byte.

The Rust kernel is intentionally simple so the examples focus on interface,
input access, and return-object construction overhead.

## Packages

- [`r/RCallsRustC`](r/RCallsRustC): old-school `.Call` C wrapper plus a Rust
  `staticlib`, following the structure of
  [`r-rust/hellorust`](https://github.com/r-rust/hellorust).
- [`r/RCallsRustExtendrFfi`](r/RCallsRustExtendrFfi): an `extendr` package that
  uses `extendr_ffi` directly for raw-vector access and data-frame construction.
  R wrappers are generated from `extendr` metadata.
- [`r/RCallsRustExtendr`](r/RCallsRustExtendr): a high-level `extendr` package
  using `Raw` and `data_frame!`. R wrappers are generated from `extendr`
  metadata.
- [`r/RCallsRustSavvy`](r/RCallsRustSavvy): a
  [`savvy`](https://github.com/yutannihilation/savvy) package variant. Its C/R
  wrappers are generated with `savvy::savvy_update()`. It returns a named list
  from Rust and constructs the final `data.frame` in R, which matches savvy's
  documented recommendation for data frames.

## Make targets

From the repository root:

```sh
make deps      # install tinytest and bench
make install   # install all packages
make test      # run tinytest for all packages
make bench     # run bench::mark benchmark
make check     # run R CMD check for all packages
```

The benchmark uses the R `bench` package, a deterministic 1 MB raw vector by
default, and reports both scalar count and small-data-frame return timings.
