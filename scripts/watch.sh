#!/usr/bin/env bash

source ./scripts/core.sh

get_node_net
get_node_name

watch -n 1 kubectl -n $NAME get pods
