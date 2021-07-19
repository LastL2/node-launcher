#!/usr/bin/env bash

source ./scripts/core.sh

if ! snapshot_available; then
  warn "Snapshot not available in this cluster"
  echo
  exit 0
fi

get_node_info_short
echo "=> Select a THORNode service to snapshot"
menu thornode thornode bifrost midgard binance-daemon bitcoin-daemon bitcoin-cash-daemon ethereum-daemon litecoin-daemon
SERVICE=$MENU_SELECTED

make_snapshot "$SERVICE"
