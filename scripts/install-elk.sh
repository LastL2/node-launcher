#!/usr/bin/env bash

set -e

source ./scripts/core.sh

if helm status elastic >/dev/null 2>&1; then
  helm diff -C 3 upgrade elastic ./elastic-operator --install -n elastic-system
  confirm
fi

echo "=> Installing ELK Logs Management"
helm upgrade elastic ./elastic-operator --install -n elastic-system --create-namespace --wait
echo Waiting for services to be ready...
kubectl wait --for=condition=Ready --all pods -n elastic-system --timeout=5m
echo
