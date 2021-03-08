#!/usr/bin/env bash

source ./scripts/core.sh

get_node_info_short
echo "=> Select a THORNode service to reset"
menu midgard midgard binance-daemon thornode
SERVICE=$MENU_SELECTED

warn "Destructive command, be careful, your service data volume data will be wiped out and restarted to sync from scratch"
confirm

echo "=> Resetting service $SERVICE"
case $SERVICE in
  midgard )
    kubectl exec -it -n $NAME sts/midgard-timescaledb -- rm -rf /var/lib/postgresql/data/pgdata
    kubectl delete -n $NAME pod -l app.kubernetes.io/name=midgard
    ;;

  thor-daemon )
    kubectl scale -n $NAME --replicas=0 deploy/thornode --timeout=5m
    kubectl wait --for=delete pods -l app.kubernetes.io/name=thor-daemon -n $NAME --timeout=5m > /dev/null 2>&1 || true
    kubectl run -n $NAME -it recover-thord --rm --restart=Never --image=busybox --overrides='{"apiVersion": "v1", "spec": {"containers": [{"command": ["sh", "-c", "cd /root/.thord/data && rm -rf bak && mkdir -p bak && mv application.db blockstore.db cs.wal evidence.db state.db tx_index.db bak/"], "name": "recover-thord", "stdin": true, "stdinOnce": true, "tty": true, "image": "busybox", "volumeMounts": [{"mountPath": "/root", "name":"data"}]}], "volumes": [{"name": "data", "persistentVolumeClaim": {"claimName": "thornode"}}]}}'
    kubectl scale -n $NAME --replicas=1 deploy/thornode --timeout=5m
    ;;

  binance-daemon )
    kubectl scale -n $NAME --replicas=0 deploy/binance-daemon --timeout=5m
    kubectl wait --for=delete pods -l app.kubernetes.io/name=binance-daemon -n $NAME --timeout=5m > /dev/null 2>&1 || true
    kubectl run -n $NAME -it reset-binance --rm --restart=Never --image=busybox --overrides='{"apiVersion": "v1", "spec": {"containers": [{"command": ["rm", "-rf", "/bnb/config", "/bnb/data", "/bnb/.probe_last_height"], "name": "reset-binance", "stdin": true, "stdinOnce": true, "tty": true, "image": "busybox", "volumeMounts": [{"mountPath": "/bnb", "name":"data"}]}], "volumes": [{"name": "data", "persistentVolumeClaim": {"claimName": "binance-daemon"}}]}}'
    kubectl scale -n $NAME --replicas=1 deploy/binance-daemon --timeout=5m
    ;;
esac
