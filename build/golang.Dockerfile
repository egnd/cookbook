ARG BASE_IMG=golang:1.15-alpine

FROM ${BASE_IMG}
ENV TZ Europe/Moscow
ENV GOPROXY https://proxy.golang.org,direct
ENV GOSUMDB off
ENV GOLANGCI_VERSION 1.35.0
WORKDIR /src
RUN apk add -q --no-cache build-base tzdata openssh git make grep ca-certificates && \
    which ssh && git --version && make --version && grep --version && \
    update-ca-certificates && \
    rm -rf /var/cache/apk/* && mkdir -p .go
RUN wget -O- -nv https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b ${GOPATH}/bin v${GOLANGCI_VERSION} && \
    golangci-lint --version
RUN go get -u \
        github.com/vektra/mockery/.../ \
    2>&1 && \
    mockery --version
