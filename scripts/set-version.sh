#!/usr/bin/env bash

set -e

source ./scripts/core.sh

get_node_info_short

echo "=> Setting THORNode version"
kubectl exec -it -n "$NAME" deploy/thornode -- /kube-scripts/set-version.sh >/dev/null
sleep 5
echo THORNode version updated

display_status
