########################################################################################
# Build
########################################################################################

FROM golang:1.18-bullseye AS build

WORKDIR /app

ARG SRC_COMMIT=f9507c7e79f258aaa9a2265ca7d94e53988ffe16
ARG TAG=v8.0.0
RUN git init && \
  git remote add origin https://github.com/cosmos/gaia && \
  git fetch --depth 1 origin $TAG && \
  git checkout $SRC_COMMIT && \
  make build


########################################################################################
# Deploy
########################################################################################

FROM debian:bullseye-slim
RUN apt-get update && apt-get install --no-install-recommends -y curl jq && \
  rm -rf /var/lib/apt/lists/*
COPY --from=build /app/build/gaiad /gaiad
COPY entrypoint.sh /entrypoint.sh
COPY app.toml /etc/gaia/app.toml
CMD ["/entrypoint.sh"]
