#!/usr/bin/env bash

source ./scripts/core.sh

get_node_info_short

if ! node_exists; then
  die "No existing THORNode found, make sure this is the correct name"
fi

echo "=> Hard forking THORNode chain state at block height $boldyellow$HARDFORK_BLOCK_HEIGHT$reset from $boldgreen$NAME$reset"
confirm

IMAGE=$(kubectl -n "$NAME" get deploy/thornode -o jsonpath='{$.spec.template.spec.containers[:1].image}')
SPEC="
{
  \"apiVersion\": \"v1\",
  \"spec\": {
    \"containers\": [
      {
        \"command\": [
          \"sh\",
          \"-C\",
          \"/scripts/hard-fork.sh\"
        ],
        \"env\": [
          {
            \"name\": \"HARDFORK_BLOCK_HEIGHT\",
            \"value\":\"$HARDFORK_BLOCK_HEIGHT\"
          }
        ],
        \"name\": \"hard-fork\",
        \"stdin\": true,
        \"tty\": true,
        \"image\": \"$IMAGE\",
        \"volumeMounts\": [{\"mountPath\": \"/root\", \"name\":\"data\"}]
      }
    ],
    \"volumes\": [{\"name\": \"data\", \"persistentVolumeClaim\": {\"claimName\": \"thornode\"}}]
  }
}"

kubectl scale -n "$NAME" --replicas=0 deploy/thornode --timeout=5m
kubectl wait --for=delete pods -l app.kubernetes.io/name=thornode -n "$NAME" --timeout=5m > /dev/null 2>&1 || true
kubectl run -n "$NAME" -it --rm --quiet hard-fork --restart=Never --image="$IMAGE" --overrides="$SPEC"
# don't scale it back up after hard fork , need to run make install instead
