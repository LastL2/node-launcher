#!/usr/bin/env bash

set -euo pipefail

MIDGARD_HASHES="https://storage.googleapis.com/public-snapshots-ninerealms/midgard-blockstore/mainnet/v2/hashes"
THORNODE_RPC="https://rpc.ninerealms.com"
SNAPSHOT_INTERVAL=50000

# update mainnet midgard hashes with latest
sed -i '/thorchain-blockstore-hashes/q' midgard/templates/configmap.yaml
curl -s "$MIDGARD_HASHES" | sed -e 's/^/    /' >>midgard/templates/configmap.yaml

# get latest snapshot block
SNAPSHOT_HEIGHT=$(curl -s "$THORNODE_RPC/status" | jq -r ".result.sync_info.latest_block_height|tonumber/$SNAPSHOT_INTERVAL|floor*$SNAPSHOT_INTERVAL")
SNAPSHOT_HASH=$(curl -s "$THORNODE_RPC/block?height=$SNAPSHOT_HEIGHT" | jq -r ".result.block_id.hash")

echo "Snapshot height: $SNAPSHOT_HEIGHT"
echo "Snapshot hash: $SNAPSHOT_HASH"

sed -E -i "s/^(\s*trustHeight:) .*/\1 \"$SNAPSHOT_HEIGHT\"/" thornode-stack/chaosnet.yaml
sed -E -i "s/^(\s*trustHash:) .*/\1 \"$SNAPSHOT_HASH\"/" thornode-stack/chaosnet.yaml
