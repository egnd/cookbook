#!make

include .env
export

MAKEFLAGS += --always-make

PACKAGES=./internal/... ./pkg/...
BUILD_VERSION=dev
REGISTRY_IMAGE_PREFIX=egnd/cookbook

.PHONY: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

%:
	@:

########################################################################################################################

owner: ## Reset folder owner
	sudo chown -R $$(id -u):$$(id -u) ./
	@echo "Success"

check-conflicts: ## Find git conflicts
	@if grep -rn '^<<<\<<<< ' .; then exit 1; fi
	@if grep -rn '^===\====$$' .; then exit 1; fi
	@if grep -rn '^>>>\>>>> ' .; then exit 1; fi
	@echo "All is OK"

check-todos: ## Find TODO's
	@if grep -rn '@TO\DO:' .; then exit 1; fi
	@echo "All is OK"

check-master: ## Check for latest master in current branch
	@git remote update
	@if ! git log --pretty=format:'%H' | grep $$(git log --pretty=format:'%H' -n 1 origin/master) > /dev/null; then exit 1; fi
	@echo "All is OK"

mocks: ## Generate mocks
	@mkdir -p mocks
	mockery --all --case=underscore --recursive --outpkg=mocks --output=mocks --dir=internal
	mockery --all --case=underscore --recursive --outpkg=mocks --output=mocks --dir=pkg

test: ## Test source code
	@mkdir -p coverage
	go test -mod=readonly -race -cover -covermode=atomic -coverprofile=coverage/profile.out $(PACKAGES)
	go tool cover -func=coverage/profile.out
	go tool cover -html=coverage/profile.out -o coverage/report.html

lint: ## Lint source code
	golangci-lint run --color=always --config=.golangci.yml $(PACKAGES)

build: ## Build application
	@mkdir -p bin
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -mod=readonly -ldflags "-X 'main.appVersion=$(BUILD_VERSION)-linux-amd64'" -o bin/app-linux-amd64 cmd/cookbook/*.go
	CGO_ENABLED=0 GOOS=linux GOARCH=arm go build -mod=readonly -ldflags "-X 'main.appVersion=$(BUILD_VERSION)-linux-arm32'" -o bin/app-linux-arm32 cmd/cookbook/*.go
	@chmod +x bin/app-* && ls -lah bin

dependencies: ## Download dependencies
	go mod download

compose: compose-stop docker-build ## Run composed services
ifeq ($(wildcard docker-compose.override.yml),)
	ln -s docker-compose.debug.yml docker-compose.override.yml
endif
	docker-compose up --build --abort-on-container-exit --renew-anon-volumes

compose-stop: ## Stop composed services
ifeq ($(wildcard .env),)
	cp .env.dist .env
endif
	docker-compose down --remove-orphans --volumes

images: ## Build images required for debuging
	docker build --build-arg BASE_IMAGE=$(DC_GOLANG_BASE_IMAGE) --tag=$(DC_GOLANG_IMAGE) --file=build/golang.Dockerfile build
	docker build --build-arg BASE_IMAGE=$(DC_APP_BASE_IMAGE) --tag=$(DC_APP_BASE_IMAGE) --file=build/alpine.Dockerfile build

########################################################################################################################

docker-dependencies:
	@$(MAKE) _docker "make dependencies"
	@echo "All is OK"

docker-test:
	@$(MAKE) _docker "make mocks test"
	@echo "Detailed report at file://$$(pwd)/coverage/report.html"

docker-lint:
	@$(MAKE) _docker "make lint"
	@echo "All is OK"

docker-build:
	@$(MAKE) _docker "make build"
	@echo "All is OK"

_docker:
ifeq ($(wildcard .env),)
	cp .env.dist .env
endif
ifeq ($(wildcard go.mod),)
	touch go.mod
endif
ifeq ($(wildcard go.sum),)
	touch go.sum
endif
	rm -rf coverage bin && mkdir -p coverage bin
	docker run --rm -t --env GOPATH=/tmp/gocache --entrypoint sh \
		--volume "cookbookdepscache:/tmp/gocache:rw" \
		--volume "$$(pwd)/bin:/src/bin:rw" \
		--volume "$$(pwd)/coverage:/src/coverage:rw" \
		--volume "$$(pwd)/cmd:/src/cmd:ro" \
		--volume "$$(pwd)/internal:/src/internal:ro" \
		--volume "$$(pwd)/pkg:/src/pkg:ro" \
		--volume "$$(pwd)/.env:/src/.env:ro" \
		--volume "$$(pwd)/.golangci.yml:/src/.golangci.yml:ro" \
		--volume "$$(pwd)/go.mod:/src/go.mod:rw" \
		--volume "$$(pwd)/go.sum:/src/go.sum:rw" \
		--volume "$$(pwd)/Makefile:/src/Makefile:ro" \
		$(DC_GOLANG_IMAGE) -c "$(filter-out $@,$(MAKECMDGOALS))"
