#!/usr/bin/env bash

set -e

source ./scripts/core.sh

get_node_info_short

echo "=> Resuming node global halt"
kubectl exec -it -n "$NAME" deploy/thornode -- /kube-scripts/resume.sh >/dev/null
sleep 5
echo THORChain resumed

display_status