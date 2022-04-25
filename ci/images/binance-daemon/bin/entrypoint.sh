#!/bin/bash

set -ex

BNET=${BNET:-prod}
NODE_TYPE=${NODE_TYPE:-fullnode}
PEER_NODE=${PEER_NODE:-dataseed1.binance.org:80}
CHAIN="Binance-Chain-Tigris"
PORT=27147
EXE="ulimit -n 65535 && /usr/local/bin/bnbchaind start --home ${BNCHOME}"

if [ ! -d "${BNCHOME}/config/" ]; then
  mkdir -p ${BNCHOME}/config/
  cp /node-binary/fullnode/${BNET}/config/* ${BNCHOME}/config/

  if [[ "$BNET" == "prod" ]] && [[ "${RECOVER_NINEREALMS_SNAPSHOT:-true}" == "true" ]]; then
    # if this is after fresh install or reset, use ninerealms persistent peer snapshot
    sed -i 's/seeds = .*/seeds = ""/g' ${BNCHOME}/config/config.toml
    sed -i 's/persistent_peers = .*/persistent_peers = "c908be15c76a11ef0fe95fae33f7d5d209b3a8bc@binance.ninerealms.com:27148"/g' ${BNCHOME}/config/config.toml
    sed -i 's/private_peer_ids = .*/private_peer_ids = "c908be15c76a11ef0fe95fae33f7d5d209b3a8bc"/g' ${BNCHOME}/config/config.toml
    sed -i 's/max_num_inbound_peers = .*/max_num_inbound_peers = 1/g' ${BNCHOME}/config/config.toml
    sed -i 's/max_num_outbound_peers = .*/max_num_outbound_peers = 0/g' ${BNCHOME}/config/config.toml
  fi
fi
chown -R bnbchaind:bnbchaind ${BNCHOME}/config/

if [ ! -d "${BNCHOME}/data/" ]; then
  mkdir -p ${BNCHOME}/data/
  chown -R bnbchaind:bnbchaind ${BNCHOME}/data/
fi


# Install bnbchaind
ln -sf /node-binary/fullnode/${BNET}/bnbchaind /usr/local/bin/bnbchaind
chmod +x /usr/local/bin/bnbchaind

# Install lightd
ln -sf /node-binary/lightnode/${BNET}/lightd /usr/local/bin/lightd
chmod +x /usr/local/bin/lightd

if [ "$BNET" == "testnet" ]; then
  PEER_NODE=data-seed-pre-0-s1.binance.org:80
  CHAIN="Binance-Chain-Ganges"
  PORT=26657
  sed -i -e "s/seeds =.*/seeds = \"9612b570bffebecca4776cb4512d08e252119005@3.114.127.147:27146,8c379d4d3b9995c712665dc9a9414dbde5b30483@3.113.118.255:27146,7156d461742e2a1e569fd68426009c4194830c93@52.198.111.20:27146\"/g" ${BNCHOME}/config/config.toml
fi

if [ "$NODE_TYPE" == "lightnode" ]; then
  EXE="/usr/local/bin/lightd --chain-id $CHAIN --node tcp://$PEER_NODE --laddr tcp://0.0.0.0:$PORT --home-dir ${BNCHOME}"
fi

# Turn on console logging
sed -i 's/logToConsole = false/logToConsole = true/g' ${BNCHOME}/config/app.toml

# Enable telemetry
sed -i "s/prometheus = false/prometheus = true/g" ${BNCHOME}/config/config.toml
sed -i -e "s/prometheus_listen_addr = \":26660\"/prometheus_listen_addr = \":28660\"/g" ${BNCHOME}/config/config.toml

# advertise external ip if available
if [ ! -z $EXTERNAL_IP ]; then
  PORT=26656
  [ "$BNET" == "prod" ] && PORT=27146
  ADDR="$EXTERNAL_IP:$PORT"
  sed -i -e "s/external_address =.*/external_address = \"$ADDR\"/g" ${BNCHOME}/config/config.toml
fi

# reduce log noise
sed -i "s/consensus:info/consensus:error/g" ${BNCHOME}/config/config.toml
sed -i "s/dexkeeper:info/dexkeeper:error/g" ${BNCHOME}/config/config.toml
sed -i "s/dex:info/dex:error/g" ${BNCHOME}/config/config.toml
sed -i "s/state:info/state:error/g" ${BNCHOME}/config/config.toml

# start background process to disable statesync reactor after initial sync
statesync-cleanup.sh &

echo "Running $0 in $PWD"
su bnbchaind -c "$EXE"
