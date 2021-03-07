#!/usr/bin/env bash

source ./scripts/core.sh

get_node_net
get_node_name
get_node_service

case $SERVICE in
  midgard | midgard-timescaledb)
    kubectl exec -it -n $NAME sts/$SERVICE -- sh
    ;;
  * )
    kubectl exec -it -n $NAME deploy/$SERVICE -- sh
    ;;
esac
exit 0
