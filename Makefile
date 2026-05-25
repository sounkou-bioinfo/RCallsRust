PACKAGES = RCallsC RCallsRustC RCallsRustExtendrFfi RCallsRustExtendr RCallsRustSavvy
PACKAGE_DIRS = $(addprefix r/,$(PACKAGES))

.PHONY: help deps install test bench readme bench-report report build check clean

help:
	@echo "Targets:"
	@echo "  make deps         Install R dependencies used by tests/benchmarks/reports"
	@echo "  make install      Install all R packages"
	@echo "  make test         Run tinytest for all packages"
	@echo "  make bench        Run bench::mark benchmark script"
	@echo "  make readme       Render README.md from README.Rmd"
	@echo "  make bench-report Render benchmarks/benchmark.md from benchmarks/benchmark.Rmd"
	@echo "  make report       Render README.md and benchmark report"
	@echo "  make check        Run R CMD check for all packages"
	@echo "  make clean        Remove build artifacts"

deps:
	Rscript -e 'install.packages(c("tinytest", "bench", "rmarkdown", "knitr"))'

install: $(PACKAGES:%=install-%)

install-%:
	R CMD INSTALL r/$*

test: $(PACKAGES:%=test-%)

test-%:
	Rscript -e 'tinytest::test_package("$*")'

bench: install
	Rscript benchmarks/benchmark.R

readme: install
	Rscript -e 'rmarkdown::render("README.Rmd", output_format = "github_document", quiet = TRUE)'

bench-report: install
	Rscript -e 'rmarkdown::render("benchmarks/benchmark.Rmd", output_format = "github_document", output_file = "benchmark.md", quiet = TRUE)'

report: bench
	RCALLSRUST_BENCH_USE_CSV=true Rscript -e 'rmarkdown::render("README.Rmd", output_format = "github_document", quiet = TRUE)'
	RCALLSRUST_BENCH_USE_CSV=true Rscript -e 'rmarkdown::render("benchmarks/benchmark.Rmd", output_format = "github_document", output_file = "benchmark.md", quiet = TRUE)'

build: $(PACKAGES:%=build-%)

build-%:
	R CMD build r/$*

check: $(PACKAGES:%=check-%)

check-%:
	R CMD build r/$*
	TARBALL=$$(ls -t $*_*.tar.gz | head -n 1); \
	R CMD check --no-manual --no-vignettes "$$TARBALL"

clean:
	rm -rf *.Rcheck *.tar.gz benchmark-results
	find r -type d \( -name target -o -name .cargo -o -name '*.Rcheck' \) -prune -exec rm -rf {} +
	find r -type f \( -name '*.o' -o -name '*.so' -o -name '*.dll' -o -name '*.dylib' \) -delete
