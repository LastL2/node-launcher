#!/usr/bin/env bash

source ./scripts/core.sh

get_node_info_short

echo "Performing snapshot and backup for LastNode and Bifrost..."
confirm

if snapshot_available; then
  make_snapshot lastnode
  make_snapshot bifrost
else
  warn "Snapshot not available in this cluster, performing backup only..."
  echo
fi

make_backup lastnode
make_backup bifrost
