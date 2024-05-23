#!/usr/bin/env bash

source ./scripts/core.sh

get_node_info_short
echo "=> Select a LastNode service to reset"
menu midgard midgard lastnode ethereum-daemon-execution ethereum-daemon-beacon avalanche-daemon
SERVICE=$MENU_SELECTED

if node_exists; then
  echo
  warn "Found an existing LastNode, make sure this is the node you want to update:"
  display_status
  echo
fi

echo "=> Resetting service $boldyellow$SERVICE$reset of a LastNode named $boldyellow$NAME$reset"
echo
warn "Destructive command, be careful, your service data volume data will be wiped out and restarted to sync from scratch"
confirm

case $SERVICE in
  midgard)
    kubectl scale -n "$NAME" --replicas=0 sts/midgard-timescaledb --timeout=5m
    kubectl wait --for=delete pods midgard-timescaledb-0 -n "$NAME" --timeout=5m >/dev/null 2>&1 || true
    kubectl run -n "$NAME" -it reset-midgard --rm --restart=Never --image=busybox --overrides='{"apiVersion": "v1", "spec": {"containers": [{"command": ["rm", "-rf", "/var/lib/postgresql/data/pgdata"], "name": "reset-midgard", "stdin": true, "stdinOnce": true, "tty": true, "image": "busybox", "volumeMounts": [{"mountPath": "/var/lib/postgresql/data", "name":"data"}]}], "volumes": [{"name": "data", "persistentVolumeClaim": {"claimName": "data-midgard-timescaledb-0"}}]}}'
    kubectl scale -n "$NAME" --replicas=1 sts/midgard-timescaledb --timeout=5m
    kubectl delete -n "$NAME" pod -l app.kubernetes.io/name=midgard
    ;;

  lastnode)
    kubectl scale -n "$NAME" --replicas=0 deploy/lastnode --timeout=5m
    kubectl wait --for=delete pods -l app.kubernetes.io/name=lastnode -n "$NAME" --timeout=5m >/dev/null 2>&1 || true
    kubectl run -n "$NAME" -it recover-thord --rm --restart=Never --image=busybox --overrides='{"apiVersion": "v1", "spec": {"containers": [{"command": ["sh", "-c", "cd /root/.lastnode/data && rm -rf bak && mkdir -p bak && mv application.db blockstore.db cs.wal evidence.db state.db tx_index.db bak/"], "name": "recover-thord", "stdin": true, "stdinOnce": true, "tty": true, "image": "busybox", "volumeMounts": [{"mountPath": "/root", "name":"data"}]}], "volumes": [{"name": "data", "persistentVolumeClaim": {"claimName": "lastnode"}}]}}'
    kubectl scale -n "$NAME" --replicas=1 deploy/lastnode --timeout=5m
    ;;

  ethereum-daemon-execution)
    kubectl scale -n "$NAME" --replicas=0 deploy/ethereum-daemon --timeout=5m
    kubectl wait --for=delete pods -l app.kubernetes.io/name=ethereum-daemon -n "$NAME" --timeout=5m >/dev/null 2>&1 || true
    kubectl run -n "$NAME" -it reset-ethereum --rm --restart=Never --image=busybox --overrides='{"apiVersion": "v1", "spec": {"containers": [{"command": ["sh", "-c", "rm -rf /root/.ethereum"], "name": "reset-ethereum", "stdin": true, "stdinOnce": true, "tty": true, "image": "busybox", "volumeMounts": [{"mountPath": "/root", "name":"data"}]}], "volumes": [{"name": "data", "persistentVolumeClaim": {"claimName": "ethereum-daemon"}}]}}'
    kubectl scale -n "$NAME" --replicas=1 deploy/ethereum-daemon --timeout=5m
    ;;

  ethereum-daemon-beacon)
    kubectl scale -n "$NAME" --replicas=0 deploy/ethereum-daemon --timeout=5m
    kubectl wait --for=delete pods -l app.kubernetes.io/name=ethereum-daemon -n "$NAME" --timeout=5m >/dev/null 2>&1 || true
    kubectl run -n "$NAME" -it reset-ethereum --rm --restart=Never --image=busybox --overrides='{"apiVersion": "v1", "spec": {"containers": [{"command": ["sh", "-c", "rm -rf /root/beacon"], "name": "reset-ethereum", "stdin": true, "stdinOnce": true, "tty": true, "image": "busybox", "volumeMounts": [{"mountPath": "/root", "name":"data"}]}], "volumes": [{"name": "data", "persistentVolumeClaim": {"claimName": "ethereum-daemon"}}]}}'
    kubectl scale -n "$NAME" --replicas=1 deploy/ethereum-daemon --timeout=5m
    ;;

  avalanche-daemon)
    kubectl scale -n "$NAME" --replicas=0 deploy/avalanche-daemon --timeout=5m
    kubectl wait --for=delete pods -l app.kubernetes.io/name=avalanche-daemon -n "$NAME" --timeout=5m >/dev/null 2>&1 || true
    kubectl run -n "$NAME" -it reset-avalanche --rm --restart=Never --image=busybox --overrides='{"apiVersion": "v1", "spec": {"containers": [{"command": ["sh", "-c", "rm -rf /root/.avalanchego/db"], "name": "reset-avalanche", "stdin": true, "stdinOnce": true, "tty": true, "image": "busybox", "volumeMounts": [{"mountPath": "/root/.avalanchego", "name":"data"}]}], "volumes": [{"name": "data", "persistentVolumeClaim": {"claimName": "avalanche-daemon"}}]}}'
    kubectl scale -n "$NAME" --replicas=1 deploy/avalanche-daemon --timeout=5m
    ;;
esac
