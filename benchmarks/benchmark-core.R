benchmark_packages <- c("RCallsC", "RCallsRustC", "RCallsRustExtendrFfi", "RCallsRustExtendr", "RCallsRustSavvy")

param_int <- function(env, default) {
  value <- Sys.getenv(env, unset = "")
  if (nzchar(value)) as.integer(value) else as.integer(default)
}

benchmark_cpu_affinity <- function() {
  value <- Sys.getenv("RCALLSRUST_BENCH_CPU", unset = "")
  if (nzchar(value)) value else "not pinned"
}

check_benchmark_packages <- function(packages = benchmark_packages) {
  for (pkg in packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) stop("Package not installed: ", pkg)
  }
  if (!requireNamespace("bench", quietly = TRUE)) stop("Package not installed: bench")
  if (!requireNamespace("ggplot2", quietly = TRUE)) stop("Package not installed: ggplot2")
}

make_benchmark_input <- function(n = param_int("RCALLSRUST_BENCH_N", 1000000L), needle = as.raw(0x41)) {
  x <- as.raw(rep(c(0x43, 0x47, 0x54, 0x43, 0x47, 0x43, 0x54, 0x47), length.out = n))
  # Keep the data-frame result small and stable while the scan remains n bytes.
  x[seq.int(1000L, n, by = 100000L)] <- needle
  list(x = x, needle = needle)
}

benchmark_rds_path <- function(output_csv) {
  sub("\\.csv$", ".rds", output_csv)
}

read_rcallsrust_benchmark <- function(
  output_csv = Sys.getenv("RCALLSRUST_BENCH_OUT", "benchmark-results/r-calls-rust.csv"),
  output_rds = benchmark_rds_path(output_csv)
) {
  results <- utils::read.csv(output_csv, stringsAsFactors = FALSE)
  cpu_affinity <- if ("cpu_affinity" %in% names(results)) results$cpu_affinity[[1L]] else benchmark_cpu_affinity()
  results$cpu_affinity <- NULL
  mark <- if (file.exists(output_rds)) readRDS(output_rds) else NULL
  count_row <- match("pure C count", results$binding)
  if (is.na(count_row)) count_row <- 1L
  list(
    results = results,
    mark = mark,
    input = data.frame(
      input_bytes = results$input_bytes[[1L]],
      needle = 65L,
      expected_matches = results$result_size[[count_row]],
      iterations = results$iterations[[1L]],
      cpu_affinity = cpu_affinity
    ),
    output_csv = output_csv,
    output_rds = output_rds
  )
}

run_rcallsrust_benchmark <- function(
  n = param_int("RCALLSRUST_BENCH_N", 1000000L),
  iterations = param_int("RCALLSRUST_BENCH_ITERS", 1000L),
  output_csv = Sys.getenv("RCALLSRUST_BENCH_OUT", "benchmark-results/r-calls-rust.csv"),
  output_rds = benchmark_rds_path(output_csv)
) {
  check_benchmark_packages()
  input <- make_benchmark_input(n)
  x <- input$x
  needle <- input$needle

  benchmark_cases <- list(
    "pure C count" = function() RCallsC::count_byte(x, needle),
    "C .Call + Rust count" = function() RCallsRustC::count_byte(x, needle),
    "extendr_ffi count" = function() RCallsRustExtendrFfi::count_byte(x, needle),
    "extendr high-level count" = function() RCallsRustExtendr::count_byte(x, needle),
    "savvy count" = function() RCallsRustSavvy::count_byte(x, needle),
    "pure C data.frame" = function() RCallsC::find_byte(x, needle),
    "C .Call + Rust data.frame" = function() RCallsRustC::find_byte(x, needle),
    "extendr_ffi data.frame" = function() RCallsRustExtendrFfi::find_byte(x, needle),
    "extendr high-level data.frame" = function() RCallsRustExtendr::find_byte(x, needle),
    "savvy list + R data.frame" = function() RCallsRustSavvy::find_byte(x, needle)
  )

  result_size <- function(value) {
    if (is.data.frame(value)) nrow(value) else as.numeric(value)
  }
  result_sizes <- vapply(benchmark_cases, function(fun) result_size(fun()), numeric(1))

  marks <- lapply(names(benchmark_cases), function(label) {
    fun <- benchmark_cases[[label]]
    invisible(fun())
    out <- bench::mark(fun(), iterations = iterations, check = FALSE)
    out$binding <- label
    out
  })
  mark <- do.call(rbind, marks)
  row.names(mark) <- NULL

  times_us <- lapply(mark$time, function(x) as.numeric(x) * 1e6)
  time_quantile_us <- function(prob) {
    vapply(times_us, stats::quantile, numeric(1), probs = prob, names = FALSE)
  }

  labels <- if ("binding" %in% names(mark)) mark$binding else as.character(mark$expression)

  results <- data.frame(
    binding = labels,
    input_bytes = length(x),
    iterations = iterations,
    result_size = as.numeric(result_sizes[labels]),
    min_us = as.numeric(mark$min) * 1e6,
    p25_us = time_quantile_us(0.25),
    median_us = as.numeric(mark$median) * 1e6,
    p75_us = time_quantile_us(0.75),
    p95_us = time_quantile_us(0.95),
    max_us = vapply(times_us, max, numeric(1)),
    itr_per_second = mark$`itr/sec`,
    mem_alloc_bytes = as.numeric(mark$mem_alloc),
    gc_per_second = mark$`gc/sec`,
    stringsAsFactors = FALSE
  )
  results <- results[order(results$median_us), ]
  row.names(results) <- NULL

  if (!is.null(output_csv) && nzchar(output_csv)) {
    dir.create(dirname(output_csv), recursive = TRUE, showWarnings = FALSE)
    results_csv <- results
    results_csv$cpu_affinity <- benchmark_cpu_affinity()
    utils::write.csv(results_csv, output_csv, row.names = FALSE)
  }
  if (!is.null(output_rds) && nzchar(output_rds)) {
    dir.create(dirname(output_rds), recursive = TRUE, showWarnings = FALSE)
    saveRDS(mark, output_rds)
  }

  list(
    results = results,
    mark = mark,
    input = data.frame(
      input_bytes = length(x),
      needle = as.integer(needle),
      expected_matches = as.numeric(result_sizes[["pure C count"]]),
      iterations = iterations,
      cpu_affinity = benchmark_cpu_affinity()
    ),
    output_csv = output_csv,
    output_rds = output_rds
  )
}

get_rcallsrust_benchmark <- function(
  n = param_int("RCALLSRUST_BENCH_N", 1000000L),
  iterations = param_int("RCALLSRUST_BENCH_ITERS", 1000L),
  output_csv = Sys.getenv("RCALLSRUST_BENCH_OUT", "benchmark-results/r-calls-rust.csv"),
  output_rds = benchmark_rds_path(output_csv),
  use_existing = identical(tolower(Sys.getenv("RCALLSRUST_BENCH_USE_CSV", "false")), "true")
) {
  if (use_existing && file.exists(output_csv)) {
    read_rcallsrust_benchmark(output_csv, output_rds)
  } else {
    run_rcallsrust_benchmark(n = n, iterations = iterations, output_csv = output_csv, output_rds = output_rds)
  }
}

plot_rcallsrust_benchmark <- function(mark, type = "boxplot", log_scale = TRUE) {
  if (is.null(mark)) {
    return(NULL)
  }

  labels <- if ("binding" %in% names(mark)) mark$binding else as.character(mark$expression)
  time_df <- do.call(rbind, lapply(seq_along(labels), function(i) {
    data.frame(
      binding = labels[[i]],
      microseconds = as.numeric(mark$time[[i]]) * 1e6,
      stringsAsFactors = FALSE
    )
  }))
  levels <- names(sort(tapply(time_df$microseconds, time_df$binding, stats::median)))
  time_df$binding <- factor(time_df$binding, levels = levels)

  plot <- ggplot2::ggplot(time_df, ggplot2::aes(x = binding, y = microseconds, fill = binding))
  plot <- switch(
    type,
    jitter = plot + ggplot2::geom_jitter(width = 0.15, height = 0, alpha = 0.25, size = 0.7),
    violin = plot + ggplot2::geom_violin(fill = "grey85", colour = "grey30"),
    boxplot = plot + ggplot2::geom_boxplot(outlier.alpha = 0.35),
    plot + ggplot2::geom_boxplot(outlier.alpha = 0.35)
  )

  if (isTRUE(log_scale)) {
    plot <- plot + ggplot2::scale_y_log10()
    y_label <- "microseconds per call (log10 scale)"
  } else {
    y_label <- "microseconds per call"
  }

  plot +
    ggplot2::labs(x = NULL, y = y_label, title = "R-to-native call timing distribution") +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1, vjust = 1),
      legend.position = "none"
    )
}
