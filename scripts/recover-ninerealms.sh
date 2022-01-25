#!/usr/bin/env bash

set -e

source ./scripts/core.sh

echo "Nine Realms only provides mainnet snapshots. Continue?"
confirm
NET="mainnet"

get_node_info_short

if ! node_exists; then
  die "No existing THORNode found, make sure this is the correct name"
fi

HEIGHT=3865589

echo "=> Recovering height Nine Realms snapshot at height $HEIGHT in THORNode in $boldgreen$NAME$reset"
confirm

IMAGE="google/cloud-sdk"

# stop thornode
echo "stopping thornode..."
kubectl scale -n "$NAME" --replicas=0 deploy/thornode --timeout=5m
kubectl wait --for=delete pods -l app.kubernetes.io/name=thornode -n "$NAME" --timeout=5m >/dev/null 2>&1 || true

# create recover pod
echo "creating recover pod"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: recover-thornode
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
    - mountPath: /root
      name: data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: thornode
EOF

# reset node state
echo "waiting for recover pod to be ready..."
kubectl wait --for=condition=ready pods/recover-thornode -n "$NAME" --timeout=5m >/dev/null 2>&1
echo "clearing thornode data..."
kubectl exec -n "$NAME" -it recover-thornode -- /bin/sh -c 'rm -rf /root/.thornode/data/*'
echo "resetting validator state..."
kubectl exec -n "$NAME" -it recover-thornode -- /bin/sh -c '
echo "{\"height\":\"0\",\"round\":0,\"step\":0}" > /root/.thornode/data/priv_validator_state.json'

# note to user on resume
echo "${boldyellow}If the snapshot fails to sync resume with the following:$reset"
echo kubectl exec -n "$NAME" -it recover-thornode -- gsutil -m rsync -i -r \\
echo "  gs://public-snapshots-ninerealms/thornode/$HEIGHT/ /root/.thornode/data/"
echo

# unset gcloud account to access public bucket in GKE clusters with workload identity
kubectl exec -n "$NAME" -it recover-thornode -- /bin/sh -c 'gcloud config set account none'

# recover nine realms snapshot
echo "pulling nine realms snapshot..."
kubectl exec -n "$NAME" -it recover-thornode -- gsutil -m rsync -i -r \
  "gs://public-snapshots-ninerealms/thornode/$HEIGHT/" /root/.thornode/data/

echo "=> ${boldgreen}Proceeding to clean up recovery pod and restart thornode$reset"
confirm

echo "cleaning up recover pod"
kubectl -n "$NAME" delete pod/recover-thornode

# start thornode
kubectl scale -n "$NAME" --replicas=1 deploy/thornode --timeout=5m
