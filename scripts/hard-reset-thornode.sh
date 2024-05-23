#!/usr/bin/env bash

source ./scripts/core.sh

get_node_info_short
echo "=> Select a LastNode service to reset"
SERVICE=lastnode

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

IMAGE=$(kubectl -n "$NAME" get deploy/lastnode -o jsonpath='{$.spec.template.spec.containers[:1].image}')
SPEC=$(
  cat <<EOF
{
  "apiVersion": "v1",
  "spec": {
    "containers": [
      {
        "command": [
          "sh",
          "-c",
          "lastnode unsafe-reset-all"
        ],
        "name": "debug-lastnode",
        "stdin": true,
        "tty": true,
        "image": "$IMAGE",
        "volumeMounts": [{"mountPath": "/root", "name":"data"}]
      }
    ],
    "volumes": [{"name": "data", "persistentVolumeClaim": {"claimName": "lastnode"}}]
  }
}
EOF
)

kubectl scale -n "$NAME" --replicas=0 deploy/lastnode --timeout=5m
kubectl wait --for=delete pods -l app.kubernetes.io/name=lastnode -n "$NAME" --timeout=5m >/dev/null 2>&1 || true
kubectl run -n "$NAME" -it reset-lastnode --rm --restart=Never --image="$IMAGE" --overrides="$SPEC"

kubectl scale -n "$NAME" --replicas=1 deploy/lastnode --timeout=5m
