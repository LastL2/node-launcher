#!/usr/bin/env bash

source ./scripts/core.sh

get_node_info_short

warn "!!! Destructive command, only apply in case of consensus failure on thornode !!!"
warn "Be careful, your thornode data will be deleted, the service will restart and sync again"
confirm

echo "=> Resetting THORNode"
kubectl scale -n $NAME --replicas=0 deploy/thornode --timeout=5m
kubectl wait --for=delete pods -l app.kubernetes.io/name=thornode -n $NAME --timeout=5m > /dev/null 2>&1 || true
kubectl run -n $NAME -it recover-thord --rm --restart=Never --image=busybox --overrides='{"apiVersion": "v1", "spec": {"containers": [{"command": ["sh", "-c", "cd /root/.thord/data && rm -rf bak && mkdir -p bak && mv application.db blockstore.db cs.wal evidence.db state.db tx_index.db bak/"], "name": "recover-thord", "stdin": true, "stdinOnce": true, "tty": true, "image": "busybox", "volumeMounts": [{"mountPath": "/root", "name":"data"}]}], "volumes": [{"name": "data", "persistentVolumeClaim": {"claimName": "thornode"}}]}}'
kubectl scale -n $NAME --replicas=1 deploy/thornode --timeout=5m
