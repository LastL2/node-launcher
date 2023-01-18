#!/usr/bin/env bash

source ./scripts/core.sh

case $NET in
  mainnet)
    EXTRA_ARGS="-f ./thornode-stack/chaosnet.yaml"
    ;;
  stagenet)
    EXTRA_ARGS="-f ./thornode-stack/stagenet.yaml"
    ;;
  testnet)
    EXTRA_ARGS="-f ./thornode-stack/testnet.yaml"
    ;;
esac

get_node_info

if node_exists; then
  warn "Found an existing THORNode, make sure this is the node you want to update"
  display_status
  echo
fi

echo -e "=> Deploying a $boldgreen$TYPE$reset THORNode on $boldgreen$NET$reset named $boldgreen$NAME$reset"
confirm

create_namespace
if [ "$TYPE" != "daemons" ]; then
  create_password
  create_mnemonic
fi
