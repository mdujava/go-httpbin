.PHONY: clean deploy deps image imagepush lint run stagedeploy test testci testcover

# The version that will be used in docker tags (e.g. to push a
# go-httpbin:latest image use `make imagepush VERSION=latest)`
VERSION        ?= $(shell git rev-parse --short HEAD)

# Override these values to deploy to a different App Engine project
GCLOUD_PROJECT ?= httpbingo
GCLOUD_ACCOUNT ?= mccutchen@gmail.com

# Built binaries will be placed here
DIST_PATH  	  ?= dist

# Default flags used by the test, testci, testcover targets
COVERAGE_PATH ?= coverage.txt
COVERAGE_ARGS ?= -covermode=atomic -coverprofile=$(COVERAGE_PATH)
TEST_ARGS     ?= -race

# Tool dependencies
TOOL_BIN_DIR     ?= $(shell go env GOPATH)/bin
TOOL_GOLINT      := $(TOOL_BIN_DIR)/golint
TOOL_STATICCHECK := $(TOOL_BIN_DIR)/staticcheck

GO_SOURCES = $(wildcard **/*.go)

GENERATED_ASSETS_PATH := httpbin/assets/assets.go

# =============================================================================
# build
# =============================================================================
build: $(DIST_PATH)/go-httpbin

$(DIST_PATH)/go-httpbin: $(GO_SOURCES)
	mkdir -p $(DIST_PATH)
	go build -o $(DIST_PATH)/go-httpbin ./cmd/go-httpbin

buildtests:
	CGO_ENABLED=0 go test -ldflags="-s -w" -v -c -o $(DIST_PATH)/go-httpbin.test ./httpbin

clean:
	rm -rf $(DIST_PATH) $(COVERAGE_PATH)

# =============================================================================
# test & lint
# =============================================================================
test:
	go test $(TEST_ARGS) ./...

# Test command to run for continuous integration, which includes code coverage
# based on codecov.io's documentation:
# https://github.com/codecov/example-go/blob/b85638743b972bd0bd2af63421fe513c6f968930/README.md
testci:
	go test $(TEST_ARGS) $(COVERAGE_ARGS) ./...

testcover: testci
	go tool cover -html=$(COVERAGE_PATH)

lint: $(GOLINT)
	test -z "$$(gofmt -d -s -e .)" || (gofmt -d -s -e . ; exit 1)
	$(GOLINT) -set_exit_status ./...
	go vet ./...


# =============================================================================
# deploy & run locally
# =============================================================================
deploy: build
	gcloud --account=$(GCLOUD_ACCOUNT) app deploy --quiet --project=$(GCLOUD_PROJECT) --version=$(VERSION) --promote

stagedeploy: build
	gcloud --account=$(GCLOUD_ACCOUNT) app deploy --quiet --project=$(GCLOUD_PROJECT) --version=$(VERSION) --no-promote

run: build
	$(DIST_PATH)/go-httpbin


# =============================================================================
# docker images
# =============================================================================
image: build
	docker build -t mccutchen/go-httpbin:$(VERSION) .

imagepush: image
	docker push mccutchen/go-httpbin:$(VERSION)


# =============================================================================
# dependencies
# =============================================================================
$(TOOL_GOLINT):
	go install golang.org/x/lint/golint@latest

$(GOLINT):
	go get -u golang.org/x/lint/golint
