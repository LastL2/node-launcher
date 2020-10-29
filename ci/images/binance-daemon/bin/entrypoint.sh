#!/bin/bash

set -ex

BNET=${BNET:-prod}
NODE_TYPE=${NODE_TYPE:-fullnode}
PEER_NODE=${PEER_NODE:-dataseed1.binance.org:80}
CHAIN="Binance-Chain-Tigris"
PORT=27147
EXE="ulimit -n 65535 && /usr/local/bin/bnbchaind start --home ${BNCHOME}"

if [ ! -d "${BNCHOME}/config/" ]; then
set -ex
  mkdir -p ${BNCHOME}/config/
  cp /node-binary/fullnode/${BNET}/config/* ${BNCHOME}/config/
  chown -R bnbchaind:bnbchaind ${BNCHOME}/config/
fi

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
  # sed -i -e "s/seeds =.*/seeds = \"aea74b16d28d06cbfbb1179c177e8cd71315cce4@ac6d84c3f243a11e98ced0ac108d49f7-704ea117aa391bbe.elb.ap-northeast-1.amazonaws.com:27146,9612b570bffebecca4776cb4512d08e252119005@a0b88b324243a11e994280efee3352a7-96b6996626c6481d.elb.ap-northeast-1.amazonaws.com:27146,8c379d4d3b9995c712665dc9a9414dbde5b30483@aa1e4d0d1243a11e9a951063f6065739-7a82be90a58744b6.elb.ap-northeast-1.amazonaws.com:27146,7156d461742e2a1e569fd68426009c4194830c93@aa841c226243a11e9a951063f6065739-eee556e439dc6a3b.elb.ap-northeast-1.amazonaws.com:27146,2726550182cbc5f4618c27e49c730752a96901e8@a41086771245011e988520ad55ba7f5a-5f7331395e69b0f3.elb.us-east-1.amazonaws.com:27146,34ac6eb6cd914014995b5929be8d7bc9c16f724d@aa13359cd244f11e988520ad55ba7f5a-c3963b80c9b991b7.elb.us-east-1.amazonaws.com:27146,fe5eb5a945598476abe4826a8d31b9f8da7b1a54@aa35ed7c1244f11e988520ad55ba7f5a-bbfb4fe79dee5d7e.elb.us-east-1.amazonaws.com:27146\"/g" ${BNCHOME}/config/config.toml
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


echo "Running $0 in $PWD"
su bnbchaind -c "$EXE"
