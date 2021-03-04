#!/usr/bin/env bash

set -e

source ./scripts/core.sh

get_node_net
get_node_name

echo "=> Destroying Telegram bot in $boldgreen$NAME$reset"
confirm
helm delete telegram-bot -n $NAME
