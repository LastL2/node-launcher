FROM ubuntu:20.04

ARG HOST_USER_UID=1000
ARG HOST_USER_GID=1000

ARG FULLNODE_TESTNET=0.9.0
ARG FULLNODE_PROD=0.9.0

ARG LIGHTNODE_TESTNET=0.8.3
ARG LIGHTNODE_PROD=0.8.3

ARG CLI_TESTNET=0.9.0
ARG CLI_PROD=0.9.0

ARG REPO_URL=https://github.com/binance-chain/node-binary/raw/master

ENV BNCHOME=/opt/bnbchaind

RUN apt-get update && apt-get install -y --no-install-recommends curl jq ca-certificates

# Copy binaries for cli tool
RUN curl -Ls --create-dirs -o /usr/local/bin/tbnbcli ${REPO_URL}/cli/testnet/${CLI_TESTNET}/linux/tbnbcli \
  && curl -Ls --create-dirs -o /usr/local/bin/bnbcli ${REPO_URL}/cli/prod/${CLI_PROD}/linux/bnbcli \

  # Copy binaries for lightd
  && curl -Ls --create-dirs -o /node-binary/lightnode/testnet/lightd ${REPO_URL}/lightnode/testnet/${LIGHTNODE_TESTNET}/linux/lightd \
  && curl -Ls --create-dirs -o /node-binary/lightnode/prod/lightd ${REPO_URL}/lightnode/prod/${LIGHTNODE_PROD}/linux/lightd \

  # Copy binaries for bnbchaind
  && curl -Ls --create-dirs -o /node-binary/fullnode/testnet/bnbchaind ${REPO_URL}/fullnode/testnet/${FULLNODE_TESTNET}/linux/bnbchaind \
  && curl -Ls --create-dirs -o /node-binary/fullnode/prod/bnbchaind ${REPO_URL}/fullnode/prod/${FULLNODE_PROD}/linux/bnbchaind \

  # Copy binary for state_recover
  && curl -Ls --create-dirs -o /node-binary/tools/state_recover ${REPO_URL}/tools/recover/linux/state_recover \

  # Copy config files for testnet and prod chains of fullnode
  && curl -Ls --create-dirs -o /node-binary/fullnode/testnet/config/app.toml ${REPO_URL}/fullnode/testnet/${FULLNODE_TESTNET}/config/app.toml \
  && curl -Ls --create-dirs -o /node-binary/fullnode/testnet/config/config.toml ${REPO_URL}/fullnode/testnet/${FULLNODE_TESTNET}/config/config.toml \
  && curl -Ls --create-dirs -o /node-binary/fullnode/testnet/config/genesis.json ${REPO_URL}/fullnode/testnet/${FULLNODE_TESTNET}/config/genesis.json \
  && curl -Ls --create-dirs -o /node-binary/fullnode/prod/config/app.toml ${REPO_URL}/fullnode/prod/${FULLNODE_PROD}/config/app.toml \
  && curl -Ls --create-dirs -o /node-binary/fullnode/prod/config/config.toml ${REPO_URL}/fullnode/prod/${FULLNODE_PROD}/config/config.toml \
  && curl -Ls --create-dirs -o /node-binary/fullnode/prod/config/genesis.json ${REPO_URL}/fullnode/prod/${FULLNODE_PROD}/config/genesis.json

# Copy scripts
COPY ./bin/*.sh /usr/local/bin/

RUN set -ex \
&& chmod +x /usr/local/bin/*.sh /node-binary/tools/* \
&& mkdir -p "$BNCHOME" \
&& groupadd --gid "$HOST_USER_GID" bnbchaind \
&& useradd --uid "$HOST_USER_UID" --gid "$HOST_USER_GID" --shell /bin/bash --no-create-home bnbchaind \
&& chown -R bnbchaind:bnbchaind "$BNCHOME" /node-binary

VOLUME ${BNCHOME}

# RPC service listen on port 27147 and P2P service listens on port 27146 by default.
# Prometheus is enabled on port 26660 by default, and the endpoint is /metrics.
EXPOSE 27146 27147 26656 26657 26660

ENTRYPOINT ["entrypoint.sh"]
