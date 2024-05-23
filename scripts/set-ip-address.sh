#!/usr/bin/env bash

set -e

source ./scripts/core.sh

get_node_info_short

GATEWAY=$(kubectl -n "${NAME}" get configmap gateway-external-ip -o jsonpath="{.data.externalIP}")
IP_ADDRESS="${IP_ADDRESS:-${GATEWAY}}"

echo "=> Setting LastNode IP address"
kubectl exec -it -n "$NAME" deploy/lastnode -- /kube-scripts/set-ip-address.sh "$IP_ADDRESS"
sleep 5
echo LastNode IP address updated to "${IP_ADDRESS}"
