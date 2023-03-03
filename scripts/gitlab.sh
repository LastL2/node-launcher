#!/bin/sh

gitlab_registry_token() {
  scope=$(jq -rn --arg x "repository:$1:pull" '$x|@uri')
  curl -s "https://gitlab.com/jwt/auth?service=container_registry&scope=$scope" |
    jq -r .token
}

gitlab_registry_digest() {
  registry=$(jq -rn --arg x "$1" '$x|@uri')
  tag="$2"
  token="$3"

  curl -I -s \
    -H "Authorization: Bearer ${token}" \
    "https://registry.gitlab.com/v2/${registry}/manifests/${tag}" |
    awk -F'[[:space:]]' '/Docker-Content-Digest/ { print $2 }'
}
