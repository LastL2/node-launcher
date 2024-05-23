#!/usr/bin/env bash

set -e

source ./scripts/core.sh

get_node_info_short

echo "=> Setting LastNode version"
kubectl exec -it -n "$NAME" -c lastnode deploy/lastnode -- /kube-scripts/retry.sh /kube-scripts/set-version.sh
sleep 5
echo LastNode version updated

display_status
