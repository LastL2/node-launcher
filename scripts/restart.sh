#!/usr/bin/env bash

source ./scripts/core.sh

get_node_net
get_node_name
get_node_service

kubectl delete -n $NAME pod -l app.kubernetes.io/name=$SERVICE
