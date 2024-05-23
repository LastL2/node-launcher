#!/usr/bin/env bash

source ./scripts/core.sh

get_node_info_short
get_txids

echo "=> Attempting re-observe of the following inbound transactions:"
echo "${TXIDS}"
echo
confirm

kubectl exec -it -n "${NAME}" -c lastnode deploy/lastnode -- /kube-scripts/observe-tx-ins.sh "${TXIDS}"
