#!/usr/bin/env bash

source ./scripts/core.sh

get_node_info_short
get_discord_channel
get_discord_message

kubectl exec -it -n "$NAME" -c thornode deploy/thornode -- /kube-scripts/relay.sh "$DISCORD_CHANNEL" "$DISCORD_MESSAGE" >/dev/null
