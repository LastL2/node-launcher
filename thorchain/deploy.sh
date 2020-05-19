#!/bin/sh
# deploy.sh
# deploy.sh testnet
# deploy.sh mocknet 12 1.2.3.4 2.3.4.5

set -e

RELEASE=${1:-mainnet}
NODES=${2:-1}
PEER=${3:-thor-daemon.$RELEASE-1}
PEER_API=${4:-thor-api.$RELEASE-1}

if [ $RELEASE != "mainnet" ]; then
  FILE="-f $RELEASE.yaml"
fi

for i in `seq 1 $NODES`
do
		if [ $i = 1 ]
    then
      echo Deploying $RELEASE in namespace $RELEASE-$i
			helm upgrade --install $RELEASE . -n $RELEASE-$i --create-namespace $FILE
		else
			MNEMONIC=$(docker run namick/12-words)
			cat << EOF > tmp.yaml
thor-daemon:
  peer: $PEER
  peerApi: $PEER_API
  signer:
    mnemonic: $MNEMONIC
bifrost:
  signer:
    mnemonic: $MNEMONIC
EOF
      echo Deploying $RELEASE in namespace $RELEASE-$i
			helm upgrade --install $RELEASE . -n $RELEASE-$i --create-namespace $FILE -f tmp.yaml
      rm tmp.yaml
		fi
done
