#!/usr/bin/env bash

source ./scripts/core.sh

if ! snapshot_available; then
  warn "Snapshot not available in this cluster"
  echo
  exit 0
fi

get_node_info_short
echo "=> Select a THORNode service to restore a snapshot"
menu thornode thornode bifrost midgard binance-daemon bitcoin-daemon bitcoin-cash-daemon ethereum-daemon litecoin-daemon
SERVICE=$MENU_SELECTED
echo

if ! kubectl -n "$NAME" get volumesnapshot "$SERVICE" >/dev/null 2>&1; then
  warn "No snapshot found for that service $boldyellow$SERVICE$reset"
  echo
  exit 0
fi

echo "=> Restoring service $boldyellow$SERVICE$reset of a THORNode named $boldyellow$NAME$reset from snapshot"
echo
warn "Destructive command, be careful, your service data volume data will be wiped out and restarted from a snapshot"
confirm

if [ "$SERVICE" == "midgard" ]; then
  PVC="data-midgard-timescaledb-0"
  kubectl scale -n "$NAME" --replicas=0 sts/midgard-timescaledb --timeout=5m
  kubectl wait --for=delete pods midgard-timescaledb-0 -n "$NAME" --timeout=5m >/dev/null 2>&1 || true
else
  PVC=$SERVICE
  kubectl scale -n "$NAME" --replicas=0 deploy/"$SERVICE" --timeout=5m
  kubectl wait --for=delete pods -l app.kubernetes.io/name="$SERVICE" -n "$NAME" --timeout=5m >/dev/null 2>&1 || true
fi

kubectl -n "$NAME" get pvc "$PVC" -o json \
  | jq 'del(.spec.volumeName,.metadata.annotations,.metadata.managedFields,.metadata.uid,.metadata.resourceVersion,.metadata.creationTimestamp)' \
  | jq ".spec += {dataSource: {name: \"$SERVICE\" ,kind: \"VolumeSnapshot\", apiGroup: \"snapshot.storage.k8s.io\"}}" \
  | kubectl -n "$NAME" replace --force -f -

if [ "$SERVICE" == "midgard" ]; then
  kubectl scale -n "$NAME" --replicas=1 sts/midgard-timescaledb --timeout=5m
else
  kubectl scale -n "$NAME" --replicas=1 deploy/"$SERVICE" --timeout=5m
fi

echo "Snapshot for $boldgreen$SERVICE$reset restored"
