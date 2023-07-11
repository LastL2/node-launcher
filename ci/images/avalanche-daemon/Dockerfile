# Upstream: https://github.com/ava-labs/avalanchego/blob/v1.7.14/Dockerfile

# Changes to the minimum golang version must also be replicated in
# scripts/ansible/roles/golang_base/defaults/main.yml
# scripts/build_avalanche.sh
# scripts/local.Dockerfile
# Dockerfile (here)
# README.md
# go.mod
# ============= Compilation Stage ================
FROM golang:1.19.6-buster AS builder

# trunk-ignore(hadolint/DL3008)
RUN apt-get update && apt-get install -y --no-install-recommends bash=5.0-4 make=4.2.1-1.2 gcc=4:8.3.0-1 musl-dev=1.1.21-2 ca-certificates=20200601~deb10u2 linux-headers-amd64

COPY version /version
ARG COMMIT=3e8552d072f0f1b8d29fcf3ec71f043f52d2c8dd
WORKDIR /build
RUN TAG="v$(cat /version)" && \
  git init && \
  git remote add origin https://github.com/ava-labs/avalanchego && \
  git fetch --depth 1 origin "$TAG" && \
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
