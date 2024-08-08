# syntax = docker/dockerfile:1.3
FROM --platform=${BUILDPLATFORM:-linux/amd64} golang:1.22 AS build

WORKDIR /go/src/github.com/mccutchen/go-httpbin

COPY . .

ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN --mount=type=cache,id=gobuild,target=/root/.cache/go-build \
    GOOS=$(dirname ${TARGETPLATFORM}) GOARCH=$(basename ${TARGETPLATFORM}) \
    make build buildtests

FROM --platform=${BUILDPLATFORM:-linux/amd64} gcr.io/distroless/base

COPY --from=build /go/src/github.com/mccutchen/go-httpbin/dist/go-httpbin* /bin/

EXPOSE 8080
CMD ["/bin/go-httpbin"]
