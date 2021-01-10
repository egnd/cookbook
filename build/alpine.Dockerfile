ARG BASE_IMG=alpine:3

FROM ${BASE_IMG}
ENV TZ Europe/Moscow
WORKDIR /src
RUN apk add -q --no-cache build-base tzdata git grep make ca-certificates && \
    update-ca-certificates && \
    rm -rf /var/cache/apk/*
