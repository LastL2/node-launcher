#!/usr/bin/env bash

source ./scripts/core.sh

SEED_TESTNET=${SEED_TESTNET:=$(curl -s https://testnet.seed.thorchain.info/ | jq -r '. | join(",")' | sed "s/,/\\\,/g;s/|/,/g")}
SEED_STAGENET=${SEED_STAGENET:="stagenet-seed.ninerealms.com"}
SEED_MAINNET=${SEED_MAINNET:=$(curl -s https://seed.thorchain.info/ | jq -r '. | join(",")' | sed "s/,/\\\,/g;s/|/,/g")}

get_node_info

if node_exists; then
  warn "Found an existing THORNode, make sure this is the node you want to update"
  display_status
  echo
fi

echo -e "=> Deploying a $boldgreen$TYPE$reset THORNode on $boldgreen$NET$reset named $boldgreen$NAME$reset"
confirm

if [ "$0" == "./scripts/update.sh" ] && snapshot_available; then
  make_snapshot "thornode"
  if [ "$TYPE" != "fullnode" ]; then
    make_snapshot "bifrost"
  fi
fi

case $NET in
  mainnet)
    SEED=$SEED_MAINNET
    EXTRA_ARGS="-f ./thornode-stack/chaosnet.yaml"
    ;;
  stagenet)
    SEED=$SEED_STAGENET
    EXTRA_ARGS="-f ./thornode-stack/stagenet.yaml"
    ;;
  testnet)
    SEED=$SEED_TESTNET
    EXTRA_ARGS="-f ./thornode-stack/testnet.yaml"
    ;;
esac

if [ -n "$HARDFORK_BLOCK_HEIGHT" ]; then
  EXTRA_ARGS="$EXTRA_ARGS --set thornode.haltHeight=$HARDFORK_BLOCK_HEIGHT"
fi

create_namespace
if [ "$TYPE" != "daemons" ]; then
  create_password
  create_mnemonic
fi

# check to ensure required CRDs are created before deploying
if ! kubectl get crd servicemonitors.monitoring.coreos.com >/dev/null 2>&1; then
  echo "=> Required ServiceMonitor CRD not found - run 'make tools' before proceeding."
  exit 1
fi

case $TYPE in
  genesis)
    deploy_genesis
    ;;
  validator)
    deploy_validator
    ;;
  fullnode)
    deploy_fullnode
    ;;
  daemons)
    EXTRA_ARGS="$EXTRA_ARGS --set thornode.enabled=false"
    EXTRA_ARGS="$EXTRA_ARGS --set bifrost.enabled=false"
    EXTRA_ARGS="$EXTRA_ARGS --set gateway.enabled=false"
    deploy_validator
    ;;
esac
