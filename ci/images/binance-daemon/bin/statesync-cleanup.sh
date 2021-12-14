#!/bin/bash

sleep 120  # wait a bit to initialize

while true; do
  echo "[statesync-cleanup] Checking for statesync cleanup"

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

  sleep 600
done
