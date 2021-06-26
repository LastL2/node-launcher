#!/usr/bin/env bash

source ./scripts/menu.sh

# reset=$(tput sgr0)              # normal text
reset=$'\e[0m'                  # (works better sometimes)
bold=$(tput bold)               # make colors bold/bright
red="$bold$(tput setaf 1)"      # bright red text
green=$(tput setaf 2)           # dim green text
boldgreen="$bold$green"         # bright green text
fawn=$(tput setaf 3)            # dark yellow text
beige="$fawn"                   # dark yellow text
yellow="$bold$fawn"             # bright yellow text
boldyellow="$bold$yellow"       # bright yellow text
darkblue=$(tput setaf 4)        # dim blue text
blue="$bold$darkblue"           # bright blue text
purple=$(tput setaf 5)          # magenta text
magenta="$purple"               # magenta text
pink="$bold$purple"             # bright magenta text
darkcyan=$(tput setaf 6)        # dim cyan text
cyan="$bold$darkcyan"           # bright cyan text
gray=$(tput setaf 7)            # dim white text
darkgray="$bold"$(tput setaf 0) # bold black = dark gray text
white="$bold$gray"              # bright white text

warn() {
  echo >&2 "$boldyellow:: $*$reset"
}

die() {
  echo >&2 "$red:: $*$reset"
  exit 1
}

confirm() {
  echo -n "$boldyellow:: Are you sure? Confirm [y/n]: $reset" && read -r ans && [ "${ans:-N}" != y ] && exit
  echo
}

get_node_net() {
  [ "$NET" != "" ] && return
  echo "=> Select net"
  menu mainnet mainnet testnet
  NET=$MENU_SELECTED
  echo
}

get_node_type() {
  [ "$TYPE" != "" ] && return
  echo "=> Select THORNode type"
  menu validator genesis validator fullnode
  TYPE=$MENU_SELECTED
  echo
}

get_node_name() {
  [ "$NAME" != "" ] && return
  [ "$NET" = "mainnet" ] && NAME=thornode || NAME=thornode-testnet
  read -r -p "=> Enter THORNode name [$NAME]: " name
  NAME=${name:-$NAME}
  echo
}

get_node_info() {
  get_node_net
  get_node_type
  get_node_name
}

get_node_info_short() {
  [ "$NAME" = "" ] && get_node_net
  get_node_name
}

get_node_service() {
  [ "$SERVICE" != "" ] && return
  echo "=> Select THORNode service"
  menu thornode thornode bifrost midgard gateway binance-daemon ethereum-daemon bitcoin-daemon litecoin-daemon bitcoin-cash-daemon midgard-timescaledb
  SERVICE=$MENU_SELECTED
  echo
}

create_namespace() {
  if ! kubectl get ns "$NAME" >/dev/null 2>&1; then
    echo "=> Creating THORNode Namespace"
    kubectl create ns "$NAME"
    echo
  fi
}

node_exists() {
  kubectl get -n "$NAME" deploy/thornode >/dev/null 2>&1 || kubectl get -n "$NAME" deploy/thor-daemon >/dev/null 2>&1
}

create_mnemonic() {
  local mnemonic
  if ! kubectl get -n "$NAME" secrets/thornode-mnemonic >/dev/null 2>&1; then
    echo "=> Generating THORNode Mnemonic phrase"
    mnemonic=$(kubectl run -n "$NAME" -it --rm mnemonic --image=registry.gitlab.com/thorchain/thornode --restart=Never --command -- generate | grep MASTER_MNEMONIC | cut -d '=' -f 2 | tr -d '\r')
    kubectl -n "$NAME" create secret generic thornode-mnemonic --from-literal=mnemonic="$mnemonic"
    echo
  fi
}

create_password() {
  [ "$NET" = "testnet" ] && return
  local pwd
  local pwdconf
  if ! kubectl get -n "$NAME" secrets/thornode-password >/dev/null 2>&1; then
    echo "=> Creating THORNode Password"
    read -r -s -p "Enter password: " pwd
    echo
    read -r -s -p "Confirm password: " pwdconf
    echo
    [ "$pwd" != "$pwdconf" ] && die "Passwords mismatch"
    kubectl -n "$NAME" create secret generic thornode-password --from-literal=password="$pwd"
    echo
  fi
}

display_mnemonic() {
  kubectl get -n "$NAME" secrets/thornode-mnemonic --template="{{.data.mnemonic}}" | base64 --decode
}

display_pods() {
  kubectl get -n "$NAME" pods
}

display_password() {
  kubectl get -n "$NAME" secrets/thornode-password --template="{{.data.password}}" | base64 --decode
}

display_status() {
  local ready
  if kubectl get -n "$NAME" deploy/thornode >/dev/null 2>&1; then
    ready=$(kubectl get pod -n "$NAME" -l app.kubernetes.io/name=thornode -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}')
    if [ "$ready" = "True" ]; then
      kubectl exec -it -n "$NAME" deploy/thornode -- /scripts/node-status.sh
    else
      echo "THORNode pod is not currently running, status is unavailable"
    fi
    return
  fi
  if kubectl get -n "$NAME" deploy/thor-daemon >/dev/null 2>&1; then
    ready=$(kubectl get pod -n "$NAME" -l app.kubernetes.io/name=thor-daemon -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}')
    if [ "$ready" = "True" ]; then
      kubectl exec -it -n "$NAME" deploy/thor-daemon -- /scripts/node-status.sh
    else
      echo "THORNode pod is not currently running, status is unavailable"
    fi
    return
  fi
}

deploy_genesis() {
  local args
  [ "$NET" = "mainnet" ] && args="--set global.passwordSecret=thornode-password"
  # shellcheck disable=SC2086
  helm upgrade --install "$NAME" ./thornode-stack -n "$NAME" \
    --create-namespace $args $EXTRA_ARGS \
    --set global.mnemonicSecret=thornode-mnemonic \
    --set global.net="$NET" \
    --set thornode.haltHeight="$HARDFORK_BLOCK_HEIGHT" \
    --set thornode.type="genesis"
}

deploy_validator() {
  local args
  [ "$NET" = "mainnet" ] && args="--set global.passwordSecret=thornode-password"
  # shellcheck disable=SC2086
  helm upgrade --install "$NAME" ./thornode-stack -n "$NAME" \
    --create-namespace $args $EXTRA_ARGS \
    --set global.mnemonicSecret=thornode-mnemonic \
    --set global.net="$NET" \
    --set thornode.haltHeight="$HARDFORK_BLOCK_HEIGHT" \
    --set thornode.type="validator" \
    --set bifrost.peer="$SEED",thornode.seeds="$SEED"
}

deploy_fullnode() {
  # shellcheck disable=SC2086
  helm upgrade --install "$NAME" ./thornode-stack -n "$NAME" \
    --create-namespace $EXTRA_ARGS \
    --set global.mnemonicSecret=thornode-mnemonic \
    --set global.net="$NET" \
    --set thornode.haltHeight="$HARDFORK_BLOCK_HEIGHT" \
    --set thornode.seeds="$SEED" \
    --set bifrost.enabled=false,binance-daemon.enabled=false \
    --set bitcoin-daemon.enabled=false,bitcoin-cash-daemon.enabled=false \
    --set litecoin-daemon.enabled=false,ethereum-daemon.enabled=false \
    --set thornode.type="fullnode",gateway.validator=false
}
