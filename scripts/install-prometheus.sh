#!/usr/bin/env bash

set -e

source ./scripts/core.sh

helm diff -C 3 upgrade --install prometheus prometheus-community/kube-prometheus-stack -n prometheus-system -f ./prometheus/values.yaml
confirm

echo "=> Installing Prometheus/Grafana Stack"
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack -n prometheus-system --create-namespace --wait -f ./prometheus/values.yaml
echo
