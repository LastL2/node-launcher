#!/usr/bin/env bash

set -e

source ./scripts/core.sh

get_node_info

if ! node_exists; then
  die "No existing THORNode found, make sure this is the correct name"
fi

source ./scripts/deploy.sh

echo
echo "=> Waiting for THORNode daemon to be ready"
sleep 20
kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=thor-daemon -n "$NAME" --timeout=5m

echo
source ./scripts/set-version.sh
