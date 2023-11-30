#!/usr/bin/env bash

set -e

NET=mainnet

source ./scripts/core.sh

get_node_info_short

# trunk-ignore(shellcheck/SC2310)
if ! node_exists; then
  die "No existing THORNode found, make sure this is the correct name"
fi

# select snapshot provider
PROVIDER="https://snapshots.ninerealms.com"
read -r -p "=> Enter provider [${PROVIDER}]: " provider
PROVIDER=${provider:-${PROVIDER}}
echo

# get all available snapshot heights
MINIO_IMAGE="minio/minio:RELEASE.2023-10-25T06-33-25Z@sha256:858ee1ca619396ea1b77cc12a36b857a6b57cb4f5d53128b1224365ee1da7305"
HEIGHTS=$(
  docker run --rm --entrypoint sh "${MINIO_IMAGE}" -c "
    mc config host add minio ${PROVIDER} '' '' >/dev/null;
    mc ls minio/snapshots/thornode --json |
      jq -r '(.key|gsub(\".tar.gz\"; \"\"))' |
      sort -nr"
)
readarray -t HEIGHTS <<<"${HEIGHTS}"

echo "=> Select block height to recover"
# shellcheck disable=SC2068
menu "${HEIGHTS[0]}" ${HEIGHTS[@]}
HEIGHT=${MENU_SELECTED}

echo "=> Recovering snapshot at height ${HEIGHT} on THORNode in ${boldgreen}${NAME}${reset}"
confirm

# stop thornode
echo "stopping thornode..."
kubectl scale -n "${NAME}" --replicas=0 deploy/thornode --timeout=5m
kubectl wait --for=delete pods -l app.kubernetes.io/name=thornode -n "${NAME}" --timeout=5m >/dev/null 2>&1 || true

# create recover pod
echo "creating recover pod"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: restore-external-thornode
  namespace: ${NAME}
spec:
  containers:
  - name: recover
    image: alpine:latest@sha256:4edbd2beb5f78b1014028f4fbb99f3237d9561100b6881aabbf5acce2c4f9454
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
kubectl wait --for=condition=ready pods/restore-external-thornode -n "${NAME}" --timeout=5m >/dev/null 2>&1

echo "clearing existing data directory..."
kubectl exec -n "${NAME}" -it restore-external-thornode -- rm -rf /root/.thornode/data/

echo "installing dependencies..."
kubectl exec -n "${NAME}" -it restore-external-thornode -- sh -c 'apk update && apk add aria2 pv'

echo "pulling snapshot..."
kubectl exec -n "${NAME}" -it restore-external-thornode -- aria2c \
  --split=16 --max-concurrent-downloads=16 --max-connection-per-server=16 \
  --continue --min-split-size=100M --out="/root/${HEIGHT}.tar.gz" \
  "${PROVIDER}/snapshots/thornode/${HEIGHT}.tar.gz"

echo "extracting snapshot..."
kubectl exec -n "${NAME}" -it restore-external-thornode -- sh -c "pv \"/root/${HEIGHT}.tar.gz\" | tar xzf - -C /root/.thornode/"

echo "removing snapshot..."
kubectl exec -n "${NAME}" -it restore-external-thornode -- rm -rf "/root/${HEIGHT}.tar.gz"

echo "=> ${boldgreen}Proceeding to clean up recovery pod and restart thornode${reset}"
confirm

echo "cleaning up recover pod"
kubectl -n "${NAME}" delete pod/restore-external-thornode

# start thornode
kubectl scale -n "${NAME}" --replicas=1 deploy/thornode --timeout=5m
