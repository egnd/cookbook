ARG BASE_IMG=alpine:3
FROM ${BASE_IMG} as base_img

FROM scratch as app
ENV TZ Europe/Moscow
WORKDIR /
COPY --from=base_img /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=base_img /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY configs configs
ENTRYPOINT ["./cookbook"]
CMD ["run"]

FROM app as linux-arm32
COPY bin/app-linux-arm32 cookbook

FROM app as linux-amd64
COPY bin/app-linux-amd64 cookbook
