# Scout — full-text search engine in Go

BINARY    := scout
CMD       := ./cmd/scout
BIN_DIR   := bin
DATA_DIR  := data
INDEX_DIR := $(DATA_DIR)/index
DATASET   ?= $(DATA_DIR)/wiki-dump
Q         ?= "query plan" AND sql
K         ?= 10

GO        := go
PKGS      := ./...

.DEFAULT_GOAL := help

.PHONY: help build run install test test-race cover bench bench-index bench-query \
        profile-cpu profile-mem fmt vet lint tidy check index query stats clean clean-data

## ---------- Build ----------

build: ## Build the scout binary into bin/
	@mkdir -p $(BIN_DIR)
	$(GO) build -o $(BIN_DIR)/$(BINARY) $(CMD)

run: build ## Build and run with ARGS="..." (e.g. make run ARGS="stats")
	./$(BIN_DIR)/$(BINARY) $(ARGS)

install: ## Install scout into $GOPATH/bin
	$(GO) install $(CMD)

## ---------- Test ----------

test: ## Run all tests
	$(GO) test $(PKGS)

test-race: ## Run tests with the race detector
	$(GO) test -race $(PKGS)

cover: ## Run tests with coverage and open the HTML report
	@mkdir -p $(BIN_DIR)
	$(GO) test -coverprofile=$(BIN_DIR)/coverage.out $(PKGS)
	$(GO) tool cover -html=$(BIN_DIR)/coverage.out

## ---------- Benchmarks & profiling ----------

bench: ## Run all benchmarks
	$(GO) test -run=^$$ -bench=. -benchmem $(PKGS)

bench-index: ## Benchmark the index package only
	$(GO) test -run=^$$ -bench=. -benchmem ./index

bench-query: ## Benchmark the query package only
	$(GO) test -run=^$$ -bench=. -benchmem ./query

profile-cpu: ## CPU profile of the bench package, opens pprof web UI
	@mkdir -p $(BIN_DIR)
	$(GO) test -run=^$$ -bench=. -cpuprofile=$(BIN_DIR)/cpu.out -o $(BIN_DIR)/bench.test ./bench
	$(GO) tool pprof -http=:8080 $(BIN_DIR)/bench.test $(BIN_DIR)/cpu.out

profile-mem: ## Memory profile of the bench package, opens pprof web UI
	@mkdir -p $(BIN_DIR)
	$(GO) test -run=^$$ -bench=. -memprofile=$(BIN_DIR)/mem.out -o $(BIN_DIR)/bench.test ./bench
	$(GO) tool pprof -http=:8080 $(BIN_DIR)/bench.test $(BIN_DIR)/mem.out

## ---------- Code quality ----------

fmt: ## Format all Go code
	$(GO) fmt $(PKGS)

vet: ## Run go vet
	$(GO) vet $(PKGS)

lint: ## Run staticcheck (go install honnef.co/go/tools/cmd/staticcheck@latest)
	staticcheck $(PKGS)

tidy: ## Tidy go.mod / go.sum
	$(GO) mod tidy

check: fmt vet test ## fmt + vet + test (run before committing)

## ---------- CLI shortcuts ----------

index: build ## Build an index from DATASET (default: data/wiki-dump)
	./$(BIN_DIR)/$(BINARY) index $(DATASET)

query: build ## Run a query: make query Q='"query plan" AND sql' K=10
	./$(BIN_DIR)/$(BINARY) query '$(Q)' -k $(K)

stats: build ## Show index stats
	./$(BIN_DIR)/$(BINARY) stats

## ---------- Cleanup ----------

clean: ## Remove build output, coverage and profiles
	rm -rf $(BIN_DIR)

clean-data: ## Remove built indexes (keeps raw datasets)
	rm -rf $(INDEX_DIR)

## ---------- Help ----------

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'
