#!/usr/bin/env bash

source ./scripts/core.sh

get_node_net
get_node_name
get_node_service

case $SERVICE in
  midgard | midgard-timescaledb)
    kubectl logs -f -n $NAME sts/$SERVICE
    ;;
  * )
    kubectl logs -f -n $NAME deploy/$SERVICE
    ;;
esac
exit 0
