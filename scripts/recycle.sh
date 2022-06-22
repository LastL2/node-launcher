#!/usr/bin/env bash

source ./scripts/core.sh

get_node_info

if ! node_exists; then
  die "No existing THORNode found, make sure this is the correct name"
fi

if [ "$TYPE" != "validator" ]; then
  die "Only validators should be recycled"
fi

display_status

echo -e "=> Recycling a $boldgreen$TYPE$reset THORNode on $boldgreen$NET$reset named $boldgreen$NAME$reset"
echo
echo
warn "!!! Make sure your got your BOND back before recycling your THORNode !!!"
confirm

# delete gateway resources
echo "=> Recycling THORNode - deleting gateway resources..."
kubectl -n "$NAME" delete deployment gateway
kubectl -n "$NAME" delete service gateway
kubectl -n "$NAME" delete configmap gateway-external-ip

# delete thornode resources
echo "=> Recycling THORNode - deleting thornode resources..."
kubectl -n "$NAME" delete deployment thornode
kubectl -n "$NAME" delete pvc thornode
kubectl -n "$NAME" delete configmap thornode-external-ip
kubectl -n "$NAME" delete secret thornode-password
kubectl -n "$NAME" delete secret thornode-mnemonic

# delete bifrost resources
echo "=> Recycling THORNode - deleting bifrost resources..."
kubectl -n "$NAME" delete deployment bifrost
kubectl -n "$NAME" delete pvc bifrost
kubectl -n "$NAME" delete configmap bifrost-external-ip

# recreate resources
echo "=> Recycling THORNode - recreating deleted resources..."
NET=$NET TYPE=$TYPE NAME=$NAME ./scripts/install.sh

echo "=> Recycle complete."
