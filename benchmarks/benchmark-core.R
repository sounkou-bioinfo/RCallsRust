benchmark_packages <- c("RCallsC", "RCallsRustC", "RCallsRustExtendrFfi", "RCallsRustExtendr", "RCallsRustSavvy")

param_int <- function(env, default) {
  value <- Sys.getenv(env, unset = "")
  if (nzchar(value)) as.integer(value) else as.integer(default)
}

check_benchmark_packages <- function(packages = benchmark_packages) {
  for (pkg in packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) stop("Package not installed: ", pkg)
  }
  if (!requireNamespace("bench", quietly = TRUE)) stop("Package not installed: bench")
}

make_benchmark_input <- function(n = param_int("RCALLSRUST_BENCH_N", 1000000L), needle = as.raw(0x41)) {
  x <- as.raw(rep(c(0x43, 0x47, 0x54, 0x43, 0x47, 0x43, 0x54, 0x47), length.out = n))
  # Keep the data-frame result small and stable while the scan remains n bytes.
  x[seq.int(1000L, n, by = 100000L)] <- needle
  list(x = x, needle = needle)
}

read_rcallsrust_benchmark <- function(output_csv = Sys.getenv("RCALLSRUST_BENCH_OUT", "benchmark-results/r-calls-rust.csv")) {
  results <- utils::read.csv(output_csv, stringsAsFactors = FALSE)
  count_row <- match("pure C count", results$binding)
  if (is.na(count_row)) count_row <- 1L
  list(
    results = results,
    mark = NULL,
    input = data.frame(
      input_bytes = results$input_bytes[[1L]],
      needle = 65L,
      expected_matches = results$result_size[[count_row]],
      iterations = results$iterations[[1L]]
    ),
    output_csv = output_csv
  )
}

run_rcallsrust_benchmark <- function(
  n = param_int("RCALLSRUST_BENCH_N", 1000000L),
  iterations = param_int("RCALLSRUST_BENCH_ITERS", 1000L),
  output_csv = Sys.getenv("RCALLSRUST_BENCH_OUT", "benchmark-results/r-calls-rust.csv")
) {
  check_benchmark_packages()
  input <- make_benchmark_input(n)
  x <- input$x
  needle <- input$needle

  result_sizes <- c(
    "pure C count" = RCallsC::count_byte(x, needle),
    "C .Call + Rust count" = RCallsRustC::count_byte(x, needle),
    "extendr_ffi count" = RCallsRustExtendrFfi::count_byte(x, needle),
    "extendr high-level count" = RCallsRustExtendr::count_byte(x, needle),
    "savvy count" = RCallsRustSavvy::count_byte(x, needle),
    "pure C data.frame" = nrow(RCallsC::find_byte(x, needle)),
    "C .Call + Rust data.frame" = nrow(RCallsRustC::find_byte(x, needle)),
    "extendr_ffi data.frame" = nrow(RCallsRustExtendrFfi::find_byte(x, needle)),
    "extendr high-level data.frame" = nrow(RCallsRustExtendr::find_byte(x, needle)),
    "savvy list + R data.frame" = nrow(RCallsRustSavvy::find_byte(x, needle))
  )

  mark <- bench::mark(
    "pure C count" = RCallsC::count_byte(x, needle),
    "C .Call + Rust count" = RCallsRustC::count_byte(x, needle),
    "extendr_ffi count" = RCallsRustExtendrFfi::count_byte(x, needle),
    "extendr high-level count" = RCallsRustExtendr::count_byte(x, needle),
    "savvy count" = RCallsRustSavvy::count_byte(x, needle),
    "pure C data.frame" = RCallsC::find_byte(x, needle),
    "C .Call + Rust data.frame" = RCallsRustC::find_byte(x, needle),
    "extendr_ffi data.frame" = RCallsRustExtendrFfi::find_byte(x, needle),
    "extendr high-level data.frame" = RCallsRustExtendr::find_byte(x, needle),
    "savvy list + R data.frame" = RCallsRustSavvy::find_byte(x, needle),
    iterations = iterations,
    check = FALSE
  )

  results <- data.frame(
    binding = as.character(mark$expression),
    input_bytes = length(x),
    iterations = iterations,
    result_size = as.numeric(result_sizes[as.character(mark$expression)]),
    min_seconds = as.numeric(mark$min),
    median_seconds = as.numeric(mark$median),
    itr_per_second = mark$`itr/sec`,
    mem_alloc_bytes = as.numeric(mark$mem_alloc),
    gc_per_second = mark$`gc/sec`,
    stringsAsFactors = FALSE
  )
  results <- results[order(results$median_seconds), ]
  row.names(results) <- NULL

  if (!is.null(output_csv) && nzchar(output_csv)) {
    dir.create(dirname(output_csv), recursive = TRUE, showWarnings = FALSE)
    utils::write.csv(results, output_csv, row.names = FALSE)
  }

  list(
    results = results,
    mark = mark,
    input = data.frame(
      input_bytes = length(x),
      needle = as.integer(needle),
      expected_matches = as.numeric(result_sizes[["pure C count"]]),
      iterations = iterations
    ),
    output_csv = output_csv
  )
}

get_rcallsrust_benchmark <- function(
  n = param_int("RCALLSRUST_BENCH_N", 1000000L),
  iterations = param_int("RCALLSRUST_BENCH_ITERS", 1000L),
  output_csv = Sys.getenv("RCALLSRUST_BENCH_OUT", "benchmark-results/r-calls-rust.csv"),
  use_existing = identical(tolower(Sys.getenv("RCALLSRUST_BENCH_USE_CSV", "false")), "true")
) {
  if (use_existing && file.exists(output_csv)) {
    read_rcallsrust_benchmark(output_csv)
  } else {
    run_rcallsrust_benchmark(n = n, iterations = iterations, output_csv = output_csv)
  }
}
