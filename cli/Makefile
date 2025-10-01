
.PHONY: build install test clean fmt lint help

# Build variables
BINARY_NAME=sops
INSTALL_PATH=/usr/local/bin
GO=go
GOFLAGS=-v

# Version info
VERSION?=$(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
LDFLAGS=-ldflags "-X github.com/ethereum-optimism/superchain-ops/cli/cmd.Version=$(VERSION)"

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build the binary
	@echo "Building $(BINARY_NAME)..."
	$(GO) build $(GOFLAGS) $(LDFLAGS) -o $(BINARY_NAME) .

install: build ## Build and install to system
	@echo "Installing $(BINARY_NAME) to $(INSTALL_PATH)..."
	@sudo mv $(BINARY_NAME) $(INSTALL_PATH)/
	@echo "✅ Installed successfully!"
	@echo "Run '$(BINARY_NAME) --help' to get started"

test: ## Run tests
	$(GO) test -v ./...

test-coverage: ## Run tests with coverage
	$(GO) test -v -coverprofile=coverage.out ./...
	$(GO) tool cover -html=coverage.out -o coverage.html

fmt: ## Format code
	$(GO) fmt ./...
	gofmt -s -w .

lint: ## Run linters
	@which golangci-lint > /dev/null || (echo "golangci-lint not installed. Run: go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest"; exit 1)
	golangci-lint run ./...

clean: ## Clean build artifacts
	@echo "Cleaning..."
	@rm -f $(BINARY_NAME)
	@rm -f coverage.out coverage.html
	@echo "✅ Cleaned"

dev: ## Build for development (no optimizations)
	$(GO) build -gcflags="all=-N -l" -o $(BINARY_NAME) .

deps: ## Download dependencies
	$(GO) mod download
	$(GO) mod tidy

upgrade-deps: ## Upgrade dependencies
	$(GO) get -u ./...
	$(GO) mod tidy

# Cross-compilation targets
build-linux: ## Build for Linux
	GOOS=linux GOARCH=amd64 $(GO) build $(LDFLAGS) -o $(BINARY_NAME)-linux-amd64 .

build-darwin: ## Build for macOS
	GOOS=darwin GOARCH=amd64 $(GO) build $(LDFLAGS) -o $(BINARY_NAME)-darwin-amd64 .
	GOOS=darwin GOARCH=arm64 $(GO) build $(LDFLAGS) -o $(BINARY_NAME)-darwin-arm64 .

build-all: build-linux build-darwin ## Build for all platforms

# Development helpers
run-simulate: build ## Quick test: run simulate command
	./$(BINARY_NAME) simulate ../src/tasks/eth/004-opcm-upgrade-v300-base --safe foundation-operations --no-ledger

run-list: build ## Quick test: list tasks
	./$(BINARY_NAME) list eth

run-nonce: build ## Quick test: check nonce
	./$(BINARY_NAME) nonce foundation-operations --network mainnet
