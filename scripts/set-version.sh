#!/usr/bin/env bash

set -e

source ./scripts/core.sh

get_node_net
get_node_name

echo "=> Setting THORNode version"
kubectl exec -it -n $NAME deploy/thornode -- /kube-scripts/set-version.sh
sleep 5

display_status
