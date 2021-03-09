#!/usr/bin/env bash

set -e

source ./scripts/core.sh

get_node_info_short

echo "=> Setting THORNode IP address"
kubectl exec -it -n "$NAME" deploy/thor-daemon -- /kube-scripts/set-ip-address.sh "$(kubectl -n "$NAME" get configmap thor-gateway-external-ip -o jsonpath="{.data.externalIP}")" > /dev/null
sleep 5
echo THORNode IP address updated
