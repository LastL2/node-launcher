#!/usr/bin/env bash

source ./scripts/core.sh

get_node_net
get_node_name

if ! node_exists; then
  die "No existing THORNode found, make sure this is the correct name"
fi

display_status

echo
echo
warn "!!! Make sure your got your BOND back before destroying your THORNode !!!"
confirm
echo "=> Deleting THORNode"
helm delete $NAME -n $NAME
kubectl delete namespace $NAME
