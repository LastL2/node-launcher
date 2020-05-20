#!/bin/sh
# deploy.sh
# deploy.sh testnet
# deploy.sh mocknet 12 1.2.3.4 2.3.4.5

set -e

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
RELEASE=${1:-mainnet}
NODES=${2:-1}
PEER=${3:-thor-daemon.$RELEASE-1}
PEER_API=${4:-thor-api.$RELEASE-1}

if [ $RELEASE != "mainnet" ]; then
  FILE="-f $SCRIPTPATH/$RELEASE.yaml"
fi

for i in `seq 1 $NODES`
do
		if [ $i = 1 ]
    then
      echo Deploying $RELEASE in namespace $RELEASE-$i
			helm upgrade --install $RELEASE $SCRIPTPATH -n $RELEASE-$i --create-namespace $FILE --set bifrost.binanceStartBlockHeight=1
		else
			MNEMONIC=$(docker run namick/12-words)
			cat << EOF > $SCRIPTPATH/tmp.yaml
thor-daemon:
  peer: $PEER
  peerApi: $PEER_API
  signer:
    mnemonic: $MNEMONIC
bifrost:
  binanceDaemon: binance-daemon.mocknet-1:26660
  bitcoinDaemon: bitcoin-daemon.mocknet-1:18443
  ethereumDaemon: ethereum-daemon.mocknet-1:8545
  signer:
    mnemonic: $MNEMONIC
binance-daemon:
  enabled: false
bitcoin-daemon:
  enabled: false
ethereum-daemon:
  enabled: false
EOF
      echo Deploying $RELEASE in namespace $RELEASE-$i
			helm upgrade --install $RELEASE $SCRIPTPATH -n $RELEASE-$i --create-namespace $FILE -f $SCRIPTPATH/tmp.yaml
      rm $SCRIPTPATH/tmp.yaml
		fi
done
