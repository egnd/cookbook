# https://github.com/microsoft/vscode-dev-containers/tree/v0.154.0/containers/go/.devcontainer/base.Dockerfile
ARG VARIANT="1"
FROM mcr.microsoft.com/vscode/devcontainers/go:0-${VARIANT}

ENV GOOS linux
ENV GOARCH amd64
ENV CGO_ENABLED 0
ENV GOPROXY https://proxy.golang.org,direct
ENV GOSUMDB off
ENV DEBIAN_FRONTEND noninteractive
ENV GOLANGCI_VERSION 1.35.0

RUN apt-get update && apt-get -y install --no-install-recommends tzdata openssh-client git make grep ca-certificates && \
    which ssh && git --version && make --version && grep --version && \
    rm -rf /var/lib/apt/lists/*

RUN wget -O- -nv https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b ${GOPATH}/bin v${GOLANGCI_VERSION} && \
    golangci-lint --version

RUN go get -u -x \
        github.com/vektra/mockery/.../ \
    2>&1 && \
    mockery --version
