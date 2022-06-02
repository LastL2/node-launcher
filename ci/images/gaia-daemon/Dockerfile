########################################################################################
# Build
########################################################################################

FROM tendermintdev/rbuilder:latest as build

ARG COMMIT=cd27aaaf39cc7819b5164e4baf3fd5aad23ec52a
ARG TAG=v7.0.2
RUN git init && \
  git remote add origin https://github.com/cosmos/gaia && \
  git fetch --depth 1 origin $TAG && \
  git checkout $COMMIT && \
  make build


########################################################################################
# Deploy
########################################################################################

FROM debian:bullseye-slim
RUN apt-get update && apt-get install --no-install-recommends -y curl jq && \
  rm -rf /var/lib/apt/lists/*
COPY --from=build /sources/build/gaiad /gaiad
COPY entrypoint.sh /entrypoint.sh
COPY app.toml /etc/gaia/app.toml
CMD ["/entrypoint.sh"]

