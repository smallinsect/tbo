LOG_PKG := tbo

TEST_PKGS := $(shell find . -iname "*_test.go" -exec dirname {} \; | \
                     uniq | sed -e "s/^\./tbo/")

GOFILTER := grep -vE 'vendor|testutil'
GOCHECKER := $(GOFILTER) | awk '{ print } END { if (NR > 0) { exit 1 } }'


default: build

all: dev

dev: build check test

build: export GO111MODULE=on
build: build-tbo

build-tbo:
ifeq ("$(WITH_RACE)", "1")
	CGO_ENABLED=1 go build -race -o bin/tbo.exe cmd/main.go
else
	CGO_ENABLED=0 go build -o bin/tbo.exe cmd/main.go
endif

test:
	# testing..
	CGO_ENABLED=1 go test -race -cover $(TEST_PKGS)

check:
	@echo "vet"
	@ go vet . 2>&1 | $(GOCHECKER)
	@echo "gofmt"
	@ gofmt -s -l . 2>&1 | $(GOCHECKER)

travis_coverage:
ifeq ("$(TRAVIS_COVERAGE)", "1")
	GOPATH=$(VENDOR) $(HOME)/gopath/bin/goveralls -service=travis-ci -ignore $(COVERIGNORE)
else
	@echo "coverage only runs in travis."
endif

tidy:
	@echo "go mod tidy"
	GO111MODULE=on go mod tidy

clean:
	rm -rf bin/*


.PHONY: update clean tbo
