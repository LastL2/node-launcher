#!/usr/bin/env bash

set -e

source ./scripts/core.sh
source ./scripts/deploy.sh

echo "=> Waiting thor THORNode daemon to be ready"
kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=thor-daemon -n $NAME --timeout=5m

echo "=> Setting THORNode version"
kubectl exec -it -n $NAME deploy/thor-daemon -- /kube-scripts/set-version.sh
sleep 5

display_status
