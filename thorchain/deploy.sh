#!/bin/sh
# deploy.sh
# deploy.sh testnet
# deploy.sh mocknet 5 123.123.123.123

set -e

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
RELEASE=${1:-mainnet}
NODES=${2:-1}
PEER=$3

if [ $RELEASE != "mainnet" ]; then
  FILE="-f $SCRIPTPATH/$RELEASE.yaml"
fi

for i in `seq 1 $NODES`
do
    NODE=$RELEASE-$i
    echo Deploying $NODE
		if [ $i = 1 ]
    then
			helm upgrade --install $RELEASE $SCRIPTPATH -n $NODE --create-namespace $FILE --set bifrost.binanceStartBlockHeight=1
		else
      PEER_NODE=$RELEASE-1
			MNEMONIC=$(docker run namick/12-words)
      # TODO create functions to handle config file for testnet
			cat << EOF > $SCRIPTPATH/tmp.yaml
thor-daemon:
  peer: ${PEER:-thor-daemon.$PEER_NODE}
  peerApi: ${PEER:-thor-api.$PEER_NODE}
  signer:
    mnemonic: $MNEMONIC
bifrost:
  peer: ${PEER:-bifrost.$PEER_NODE}
  binanceDaemon: ${PEER:-binance-daemon.$PEER_NODE:26660}
  bitcoinDaemon: ${PEER:-bitcoin-daemon.$PEER_NODE:18443}
  ethereumDaemon: ${PEER:-ethereum-daemon.$PEER_NODE:8545}
  signer:
    mnemonic: $MNEMONIC
binance-daemon:
  enabled: false
bitcoin-daemon:
  enabled: false
ethereum-daemon:
  enabled: false
EOF
			helm upgrade --install $RELEASE $SCRIPTPATH -n $NODE --create-namespace $FILE -f $SCRIPTPATH/tmp.yaml
      rm $SCRIPTPATH/tmp.yaml
		fi
done
