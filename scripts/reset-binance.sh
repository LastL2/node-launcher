#!/usr/bin/env bash

source ./scripts/core.sh

get_node_info_short

echo !!! Destructive command, be careful, your Binance node data will be wiped out and your Binance node will restart from scratch and sync again !!!
confirm

echo "=> Resetting Binance"
kubectl scale -n $NAME --replicas=0 deploy/binance-daemon --timeout=5m
kubectl wait --for=delete pods -l app.kubernetes.io/name=binance-daemon -n $NAME --timeout=5m > /dev/null 2>&1 || true
kubectl run -n $NAME -it reset-binance --rm --restart=Never --image=busybox --overrides='{"apiVersion": "v1", "spec": {"containers": [{"command": ["rm", "-rf", "/bnb/config", "/bnb/data", "/bnb/.probe_last_height"], "name": "reset-binance", "stdin": true, "stdinOnce": true, "tty": true, "image": "busybox", "volumeMounts": [{"mountPath": "/bnb", "name":"data"}]}], "volumes": [{"name": "data", "persistentVolumeClaim": {"claimName": "binance-daemon"}}]}}'
kubectl scale -n $NAME --replicas=1 deploy/binance-daemon --timeout=5m
