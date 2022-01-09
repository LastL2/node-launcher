#!/bin/bash

BINANCE_SEEDS=$(
  curl -s --fail -m 10 https://dex.binance.org/api/v1/peers | \
  jq '[.[] | select(.accelerated | not) | "\(.id)@\(.original_listen_addr)"] | join(",")'
)

while sleep 300; do

  echo "[statesync-cleanup] Checking for statesync cleanup"

  SNAPSHOT_PULLED=$(curl -s --fail -m 10 http://localhost:27147/status | jq '.result.sync_info.index_height != "0"')
  if [[ "${BNET:-prod}" == "prod" ]] && \
    [[ "${RECOVER_NINEREALMS_SNAPSHOT:-true}" == "true" ]] && \
    [[ "$SNAPSHOT_PULLED" == "true" ]] && \
    grep -q 'persistent_peer.*binance.ninerealms.com' ${BNCHOME}/config/config.toml; then

      # unset the ninerealms persistent peer
      echo "[statesync-cleanup] Synced, unsetting ninerealms persistent peer..."
      echo "[statesync-cleanup] Using new binance seeds: $BINANCE_SEEDS"
      sed -i "s/seeds = \"\"/seeds = $BINANCE_SEEDS/g" ${BNCHOME}/config/config.toml
      sed -i 's/persistent_peers = .*/persistent_peers = ""/g' ${BNCHOME}/config/config.toml
      sed -i 's/max_num_inbound_peers = .*/max_num_inbound_peers = 40/g' ${BNCHOME}/config/config.toml
      sed -i 's/max_num_outbound_peers = .*/max_num_outbound_peers = 10/g' ${BNCHOME}/config/config.toml

      pkill -HUP bnbchaind  # the daemon does not handle HUP so this will still restart
  fi

  # disable statesync reactor if synced
  SYNCED=$(curl -s --fail -m 10 http://localhost:27147/status | jq ".result.sync_info.catching_up | not")
  if [[ $SYNCED == "true" ]] && grep -q 'state_sync_reactor = true' ${BNCHOME}/config/config.toml; then
      echo "[statesync-cleanup] Synced, disabling statesync reactor..."
      sed -i "s/state_sync_reactor = true/state_sync_reactor = false/g" ${BNCHOME}/config/config.toml

      pkill -HUP bnbchaind  # the daemon does not handle HUP so this will still restart
  fi

  # remove all but the latest snapshot
  SNAPSHOTS=$(find /opt/bnbchaind/data/snapshot/ -maxdepth 1 -mindepth 1 | sort | head -n-1)
  for snapshot in $SNAPSHOTS; do
    echo "[statesync-cleanup] Removing $snapshot"
    rm -rf $snapshot
    sleep 5
  done
done
