source("benchmarks/benchmark-core.R")

bench <- run_rcallsrust_benchmark()
print(bench$results, digits = 4)
message("Wrote benchmark results to ", bench$output_csv)
message("Wrote benchmark object to ", bench$output_rds)
