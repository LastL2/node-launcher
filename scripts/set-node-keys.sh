#!/usr/bin/env bash

set -e

source ./scripts/core.sh

get_node_info_short

echo "=> Setting LastNode keys"
kubectl exec -it -n "$NAME" -c lastnode deploy/lastnode -- /kube-scripts/set-node-keys.sh
sleep 5
echo LastNode Keys updated
