#!/usr/bin/env bash

set -e

source ./scripts/core.sh

# this will fail on the first install since some crds do not exist
if helm diff -C 3 upgrade elastic ./elastic-operator --install -n elastic-system; then
  confirm
fi

echo "=> Installing ELK Logs Management"
helm upgrade elastic ./elastic-operator --install -n elastic-system --create-namespace --wait
echo Waiting for services to be ready...
kubectl wait --for=condition=Ready --all pods -n elastic-system --timeout=5m
echo
