#!/usr/bin/env bash

set -e

source ./scripts/core.sh

helm get all elastic -n elastic-system
echo -n "The above resources will be deleted "
confirm

echo "=> Deleting ELK Logs Management"
helm delete elastic -n elastic-system
kubectl delete namespace elastic-system
echo
