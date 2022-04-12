#!/usr/bin/env bash

set -e

source ./scripts/core.sh

get_node_info_short
if ! node_exists; then
  die "No existing THORNode found, make sure this is the correct name"
fi

IMAGE="registry.gitlab.com/thorchain/devops/binance-node:0.9.0"

echo "stopping binance..."
kubectl scale -n "$NAME" --replicas=0 deploy/binance-daemon --timeout=5m
kubectl wait --for=delete pods -l app.kubernetes.io/name=binance-daemon -n "$NAME" --timeout=5m >/dev/null 2>&1 || true

# create recover pod
echo "creating recover pod"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: recover-binance
  namespace: $NAME
spec:
  containers:
  - name: recover
    image: $IMAGE
    command:
      - tail
      - -f
      - /dev/null
    volumeMounts:
    - mountPath: /opt/bnbchaind/
      name: data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: binance-daemon
EOF

echo "waiting for recover pod to be ready..."
kubectl wait --for=condition=ready pods/recover-binance -n "$NAME" --timeout=5m >/dev/null 2>&1

kubectl exec -n "$NAME" -it recover-binance -- /bin/sh -c 'cp /node-binary/fullnode/prod/config/app.toml /opt/bnbchaind/config/app.toml'
kubectl exec -n "$NAME" -it recover-binance -- /bin/sh -c 'cp /node-binary/fullnode/prod/config/config.toml /opt/bnbchaind/config/config.toml'

echo "cleaning up recover pod"
kubectl -n "$NAME" delete pod/recover-binance

kubectl scale -n "$NAME" --replicas=1 deploy/binance-daemon --timeout=5m
