#!/usr/bin/env bash

set -e

source ./scripts/core.sh

get_node_info_short

echo "=> Resuming node global halt from a LastNode named $boldyellow$NAME$reset"
confirm

kubectl exec -it -n "$NAME" -c lastnode deploy/lastnode -- /kube-scripts/resume.sh
sleep 5
echo LastNetwork resumed

display_status
