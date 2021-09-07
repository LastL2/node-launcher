#!/usr/bin/env bash

set -e

source ./scripts/core.sh

get_node_info_short

echo "=> Pausing node global halt from a THORNode named $boldyellow$NAME$reset"
confirm

kubectl exec -it -n "$NAME" deploy/thornode -- /kube-scripts/pause.sh >/dev/null
sleep 5
echo THORChain paused

display_status
