#!/usr/bin/env bash

set -e

source ./scripts/core.sh

get_node_net
get_node_name

echo "=> Deploying Telegram bot in $boldgreen$NAME$reset"
echo "Start a Telegram chat with BotFather, click start, then send /newbot command."
echo -n "Enter Telegram bot token: " && read TOKEN
helm upgrade -n $NAME --install telegram-bot ./telegram-bot \
  --set telegramToken=$TOKEN \
  --set net=$NET
