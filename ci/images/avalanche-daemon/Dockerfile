# Upstream: https://github.com/ava-labs/avalanchego/blob/v1.7.14/Dockerfile

# Changes to the minimum golang version must also be replicated in
# scripts/ansible/roles/golang_base/defaults/main.yml
# scripts/build_avalanche.sh
# scripts/local.Dockerfile
# Dockerfile (here)
# README.md
# go.mod
# ============= Compilation Stage ================
FROM golang:1.17.9-buster AS builder
RUN apt-get update && apt-get install -y --no-install-recommends bash=5.0-4 git=1:2.20.1-2+deb10u3 make=4.2.1-1.2 gcc=4:8.3.0-1 musl-dev=1.1.21-2 ca-certificates=20200601~deb10u2 linux-headers-amd64

ARG COMMIT=547bdd34f9d3fa438eeaaf44efa865a9e2806148
ARG TAG=v1.7.14
WORKDIR /build
RUN git init && \
  git remote add origin https://github.com/ava-labs/avalanchego && \
  git fetch --depth 1 origin $TAG && \
  git checkout $COMMIT && \
  ./scripts/build.sh

# ============= Cleanup Stage ================
FROM debian:11-slim AS execution

# Install curl and jq for startup and liveness probes
RUN apt-get update && apt-get install -y curl jq

# Maintain compatibility with previous images
RUN mkdir -p /avalanchego/build
WORKDIR /avalanchego/build

# Copy the executables into the container
COPY --from=builder /build/build/ .

CMD [ "./avalanchego" ]
