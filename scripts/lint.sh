#!/usr/bin/env bash
set -euo pipefail

# Check for k8s definitions that aren't using explicit hashes.
UNCHAINED=$(git grep -E '^\s*image:\s*[^\s]+' | grep -v sha256)

if [ "$(printf "%s" "$UNCHAINED" | wc -l)" -ne 0 ]; then
  cat <<EOF
[ERR] Some container images are specified without an explicit hash:
$UNCHAINED
EOF
  # TODO(asmund): enable this failure exit when all hashes are pinned.
  #exit 1
fi

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
