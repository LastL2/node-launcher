#!/usr/bin/env bash

source ./scripts/core.sh

get_node_info

case $NET in
  mainnet)
    EXTRA_ARGS="-f ./lastnode-stack/mainnet.yaml"
    ;;
  stagenet)
    EXTRA_ARGS="-f ./lastnode-stack/stagenet.yaml"
    ;;
esac

if node_exists; then
  warn "Found an existing LastNode, make sure this is the node you want to update"
  display_status
  echo
fi

echo -e "=> Deploying a $boldgreen$TYPE$reset LastNode on $boldgreen$NET$reset named $boldgreen$NAME$reset"
confirm

create_namespace
if [ "$TYPE" != "daemons" ]; then
  create_password
  create_mnemonic
fi
