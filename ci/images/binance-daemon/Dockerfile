FROM ubuntu:20.04 as builder
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates wget git git-lfs binutils
RUN git lfs clone --depth 1 https://github.com/binance-chain/node-binary.git

# Final stage

FROM ubuntu:20.04

ARG HOST_USER_UID=1000
ARG HOST_USER_GID=1000

ARG FULLNODE_TESTNET=0.7.1
ARG FULLNODE_PROD=0.7.2-hf.1

ARG LIGHTNODE_TESTNET=0.6.3
ARG LIGHTNODE_PROD=0.6.3

ARG CLI_TESTNET=0.7.0
ARG CLI_PROD=0.7.2

ENV BNCHOME=/opt/bnbchaind

# Copy binaries for cli tool
COPY --from=builder /node-binary/cli/testnet/${CLI_TESTNET}/linux/tbnbcli /usr/local/bin/tbnbcli
COPY --from=builder /node-binary/cli/prod/${CLI_PROD}/linux/bnbcli /usr/local/bin/bnbcli

# Copy binaries for lightd
COPY --from=builder /node-binary/lightnode/testnet/${LIGHTNODE_TESTNET}/linux/lightd /node-binary/lightnode/testnet/lightd
COPY --from=builder /node-binary/lightnode/prod/${LIGHTNODE_PROD}/linux/lightd /node-binary/lightnode/prod/lightd

# Copy binaries for bnbchaind
COPY --from=builder /node-binary/fullnode/testnet/${FULLNODE_TESTNET}/linux/bnbchaind /node-binary/fullnode/testnet/bnbchaind
COPY --from=builder /node-binary/fullnode/prod/${FULLNODE_PROD}/linux/bnbchaind /node-binary/fullnode/prod/bnbchaind

# Copy config files for testnet and prod chains of fullnode
COPY --from=builder /node-binary/fullnode/testnet/${FULLNODE_TESTNET}/config/* /node-binary/fullnode/testnet/config/
COPY --from=builder /node-binary/fullnode/prod/${FULLNODE_PROD}/config/* /node-binary/fullnode/prod/config/

# Copy scripts
COPY ./bin/*.sh /usr/local/bin/

RUN set -ex \
&& chmod +x /usr/local/bin/*.sh \
&& mkdir -p "$BNCHOME" \
&& groupadd --gid "$HOST_USER_GID" bnbchaind \
&& useradd --uid "$HOST_USER_UID" --gid "$HOST_USER_GID" --shell /bin/bash --no-create-home bnbchaind \
&& chown -R bnbchaind:bnbchaind "$BNCHOME"

VOLUME ${BNCHOME}

# RPC service listen on port 27147 and P2P service listens on port 27146 by default.
# Prometheus is enabled on port 26660 by default, and the endpoint is /metrics.
EXPOSE 27146 27147 26656 26657 26660

ENTRYPOINT ["entrypoint.sh"]
