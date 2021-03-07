#!/usr/bin/env bash

source ./scripts/core.sh

get_node_info_short

echo !!! Destructive command, be careful, your Midgard data will be wiped out and will restart from scratch and sync again !!!
confirm

echo "=> Resetting Midgard"
kubectl exec -it -n $NAME sts/midgard-timescaledb -- rm -rf /var/lib/postgresql/data/pgdata
kubectl delete -n $NAME pod -l app.kubernetes.io/name=midgard
