#!/usr/bin/env bash

set -e

source ./scripts/core.sh

get_node_info

if ! node_exists; then
  die "No existing LastNode found, make sure this is the correct name"
fi

source ./scripts/install.sh

echo
echo "=> Waiting for LastNode daemon to be ready"
kubectl rollout status -w deployment/lastnode -n "$NAME" --timeout=5m

if [ "$TYPE" != "fullnode" ]; then
  echo
  source ./scripts/set-version.sh
fi
