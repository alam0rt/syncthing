FROM golang:1.13 AS builder

WORKDIR /src
COPY . .

ENV CGO_ENABLED=0
ENV BUILD_HOST=syncthing.net
ENV BUILD_USER=docker

RUN echo $GOBIN
RUN rm -f syncthing && go run build.go -goos linux -goarch arm -no-upgrade build syncthing

FROM alpine

EXPOSE 8384 22000 21027/udp

VOLUME ["/var/syncthing"]

RUN apk add --no-cache ca-certificates su-exec

COPY --from=builder /src/syncthing /bin/syncthing
COPY --from=builder /src/script/docker-entrypoint.sh /bin/entrypoint.sh

ENV PUID=1000 PGID=1000

HEALTHCHECK --interval=1m --timeout=10s \
  CMD nc -z localhost 8384 || exit 1

ENV STGUIADDRESS=0.0.0.0:8384
ENTRYPOINT ["/bin/entrypoint.sh", "-home", "/var/syncthing/config"]
