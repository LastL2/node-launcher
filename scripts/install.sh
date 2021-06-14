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

case $NET in
  mainnet)
    VERSION=$VERSION_MAINNET
    VERSION_MIDGARD=$VERSION_MIDGARD_MAINNET
    SEED=$SEED_MAINNET
    ;;
  testnet)
    VERSION=$VERSION_TESTNET
    VERSION_MIDGARD=$VERSION_MIDGARD_TESTNET
    SEED=$SEED_TESTNET
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
