#!/usr/bin/env sh

set -e

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

NET=${NET:-mocknet}
NODES=${NODES:-1}
TAG=${TAG:-$NET}

VALUES=$SCRIPTPATH/$NET.yaml
VALUES_MNEMONIC=$SCRIPTPATH/tmp.yaml
VALUES_VALIDATOR=$SCRIPTPATH/$NET-validator.yaml
VALUES_GENESIS=$SCRIPTPATH/$NET-genesis.yaml

set_ports () {
  case $NET in
    mocknet)
      BINANCE_PORT=26660
      BITCOIN_PORT=18443
      ETHEREUM_PORT=8545
      ;;
    testnet)
      BINANCE_PORT=26657
      BITCOIN_PORT=18332
      ETHEREUM_PORT=8545
      ;;
    mainnet)
      BINANCE_PORT=27147
      BITCOIN_PORT=8332
      ETHEREUM_PORT=8545
      ;;
  esac
}

create_mnemonic_config () {
  VALUE=${MNEMONIC:-$(docker run namick/12-words)}
  cat << EOF > $VALUES_MNEMONIC
thor-daemon:
  signer:
    mnemonic: $VALUE
bifrost:
  signer:
    mnemonic: $VALUE
EOF
}

# creates genesis config
create_genesis_config () {
  cat << EOF > $VALUES_GENESIS
thor-daemon:
  image:
    tag: "$TAG"

thor-api:
  image:
    tag: "$TAG"

bifrost:
  binanceDaemon: http://binance-daemon:$BINANCE_PORT
  binanceStartBlockHeight: 1
  image:
    tag: "$TAG"

binance-daemon:
  service:
    port:
      rpc: "$BINANCE_PORT"

midgard:
  enabled: false

bitcoin-daemon:
  enabled: false

ethereum-daemon:
  enabled: false
EOF
}

# creates validator config for a single node within the cluster
create_validator_config () {
  cat << EOF > $VALUES_VALIDATOR
thor-daemon:
  peer: $PEER
  peerApi: $PEER_API
  binanceDaemon: $PEER_BINANCE:$BINANCE_PORT
  image:
    tag: "$TAG"

thor-api:
  image:
    tag: "$TAG"

bifrost:
  peer: $PEER_BIFROST
  binanceDaemon: http://$PEER_BINANCE:$BINANCE_PORT
  image:
    tag: "$TAG"

midgard:
  enabled: false

binance-daemon:
  enabled: false

bitcoin-daemon:
  enabled: false

ethereum-daemon:
  enabled: false
EOF
}

# creates validator config for multi nodes in the same cluster
create_multi_validator_config () {
  cat << EOF > $VALUES_VALIDATOR
thor-daemon:
  peer: thor-daemon.$NET-1
  peerApi: thor-api.$NET-1
  binanceDaemon: binance-daemon.$NET-1:$BINANCE_PORT
  image:
    tag: "$TAG"

thor-api:
  image:
    tag: "$TAG"

bifrost:
  peer: bifrost.$NET-1
  binanceDaemon: http://binance-daemon.$NET-1:$BINANCE_PORT
  bitcoinDaemon: bitcoin-daemon.$NET-1:$BITCOIN_PORT
  ethereumDaemon: http://ethereum-daemon.$NET-1:$ETHEREUM_PORT
  image:
    tag: "$TAG"

midgard:
  enabled: false

binance-daemon:
  enabled: false

bitcoin-daemon:
  enabled: false

ethereum-daemon:
  enabled: false
EOF
}

# remove temporary files
clean_files () {
  rm $VALUES_VALIDATOR $VALUES_MNEMONIC $VALUES_GENESIS
}

# deploys a single node in the cluster
deploy_single_node () {
  create_mnemonic_config
  create_validator_config
  helm upgrade --install $NET $SCRIPTPATH -n $NET --create-namespace -f $VALUES -f $VALUES_MNEMONIC -f $VALUES_VALIDATOR
}
# deploys a multi nodes net within the cluster
deploy_multi_node () {

  create_genesis_config
  create_multi_validator_config

  for i in `seq 1 $NODES`; do
    NODE=$NET-$i
    echo Deploying $NODE

    create_mnemonic_config

    if [ $i = 1 ]; then
      helm upgrade --install $NET $SCRIPTPATH -n $NODE --create-namespace -f $VALUES -f $VALUES_MNEMONIC -f $VALUES_GENESIS
    else
      helm upgrade --install $NET $SCRIPTPATH -n $NODE --create-namespace -f $VALUES -f $VALUES_MNEMONIC -f $VALUES_VALIDATOR
    fi
  done
}

set_ports

if [ -z $PEER ]; then
  deploy_multi_node
else
  deploy_single_node
fi

clean_files
