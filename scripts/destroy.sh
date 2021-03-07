#!/usr/bin/env bash

source ./scripts/core.sh

get_node_net
get_node_name
display_status

echo
echo
echo !!! Make sure your got your BOND back before destroying your THORNode !!!
confirm
echo "=> Deleting THORNode"
helm delete $NAME -n $NAME
kubectl delete namespace $NAME
