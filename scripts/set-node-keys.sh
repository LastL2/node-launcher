#!/usr/bin/env bash

set -e

source ./scripts/core.sh

get_node_net
get_node_name

echo "=> Setting THORNode keys"
kubectl exec -it -n $NAME deploy/thor-daemon -- /kube-scripts/set-node-keys.sh
sleep 5
echo THORNode Keys updated
