#!/usr/bin/env bash

set -e

source ./scripts/core.sh

get_node_info

if ! node_exists; then
  die "No existing THORNode found, make sure this is the correct name"
fi

source ./scripts/deploy.sh

echo "=> Waiting thor THORNode daemon to be ready"
kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=thor-daemon -n $NAME --timeout=5m

echo "=> Setting THORNode version"
kubectl exec -it -n $NAME deploy/thor-daemon -- /kube-scripts/set-version.sh
sleep 5

display_status
