#!/usr/bin/env bash

VOTE_REMINDERS=$(
  cat <<EOF | awk -v q="\"" '{print q$1q}' | tr "\n" "," | sed 's/.$//'
  MAXSYNTHPERPOOLDEPTH
  DEPRECATEILP
EOF
)
