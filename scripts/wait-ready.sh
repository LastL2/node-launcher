#!/usr/bin/env bash

source ./scripts/core.sh

get_node_net
get_node_name

kubectl wait --for=condition=Ready --all pods -n $NAME --timeout=5m
