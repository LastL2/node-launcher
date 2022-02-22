#!/usr/bin/env bash
set -euo pipefail

# Lint shell scripts.
find . -type f -name '*.*sh' |
  while read -r SCRIPT; do
    shellcheck --external-sources --exclude SC2034 "$SCRIPT"
    shfmt -i 2 -ci -d "$SCRIPT"
  done

# Lint the Helm charts.
find . -type f -name 'Chart.yaml' -printf '%h\n' |
  while read -r CHART_DIR; do
    pushd "$CHART_DIR"
    helm lint .
    popd
  done

# TODO: enable yamllint - will be a major whitespace change across the charts.
# yamllint .
