#!/usr/bin/env bash
# Given a Docker image name, enumerate the published tags -> full hashes.
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <gitlab registry image name>"
  exit 1
fi

IMAGE="$1"

get_auth_token() {
  IMAGE="$1"
  TOKEN_URI="https://gitlab.com/jwt/auth"
  curl --silent --get \
    --data-urlencode "service=container_registry" \
    --data-urlencode "scope=repository:$IMAGE:pull" \
    $TOKEN_URI | jq --raw-output '.token'
}

get_tags() {
  IMAGE="$1"

  TOKEN=$(get_auth_token "$IMAGE")

  LIST_URI="https://registry.gitlab.com/v2/$IMAGE/tags/list"
  curl --silent --get -H "Accept: application/json" -H "Authorization: Bearer $TOKEN" "$LIST_URI" | jq --raw-output '.tags[]'
}

get_manifest() {
  IMAGE="$1"
  TAG="$2"

  TOKEN=$(get_auth_token "$IMAGE")

  MANIFEST_URI="https://registry.gitlab.com/v2/$IMAGE/manifests/$TAG"
  curl -i --silent --head -H "Accept: application/json" -H "Authorization: Bearer $TOKEN" "$MANIFEST_URI" |
    awk '/^Docker-Content-Digest:/ { print $2 }' | sed -e 's/[[:space:]]//g'
}

for TAG in $(get_tags "$IMAGE"); do
  SHA=$(get_manifest "$IMAGE" "$TAG")
  printf "%s -> %s\n" "$SHA" "$TAG"
done
