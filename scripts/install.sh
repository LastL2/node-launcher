#!/usr/bin/env bash

source ./scripts/core.sh

SEED_TESTNET=${SEED_TESTNET:=$(curl -s https://testnet.seed.thorchain.info/ | jq -r '. | join(",")' | sed "s/,/\\\,/g;s/|/,/g")}
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
  testnet)
    SEED=$SEED_TESTNET
    EXTRA_ARGS="-f ./thornode-stack/testnet.yaml"
    ;;
esac

create_namespace
create_password
create_mnemonic

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
esac
