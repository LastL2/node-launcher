#!/usr/bin/env bash

source ./scripts/core.sh

get_node_net
get_node_name

echo !!! Destructive command, only apply in case of consensus failure on thor-daemon !!!
echo Be careful, your thor-daemon data will be deleted, the service will restart and sync again
confirm

echo "=> Resetting THORNode"
kubectl scale -n $NAME --replicas=0 deploy/thor-daemon --timeout=5m
kubectl wait --for=delete pods -l app.kubernetes.io/name=thor-daemon -n $NAME --timeout=5m > /dev/null 2>&1 || true
kubectl run -n $NAME -it recover-thord --rm --restart=Never --image=busybox --overrides='{"apiVersion": "v1", "spec": {"containers": [{"command": ["sh", "-c", "cd /root/.thord/data && rm -rf bak && mkdir -p bak && mv application.db blockstore.db cs.wal evidence.db state.db tx_index.db bak/"], "name": "recover-thord", "stdin": true, "stdinOnce": true, "tty": true, "image": "busybox", "volumeMounts": [{"mountPath": "/root", "name":"data"}]}], "volumes": [{"name": "data", "persistentVolumeClaim": {"claimName": "thor-daemon"}}]}}'
kubectl scale -n $NAME --replicas=1 deploy/thor-daemon --timeout=5m
