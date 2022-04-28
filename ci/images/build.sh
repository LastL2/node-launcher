#!/bin/sh

set -euo pipefail

REGISTRY="registry.gitlab.com/thorchain/devops/node-launcher"

docker login -u "${CI_REGISTRY_USER}" -p "${CI_REGISTRY_PASSWORD}" "${CI_REGISTRY}"

find ci/images/*/version | sed -e 's,^ci/images/,,' -e 's,/.*,,' | while read -r image; do
  version=$(cat "ci/images/$image/version")

  # check to see if image version is already published
  if docker manifest inspect "$REGISTRY:${image}-${version}" > /dev/null 2>&1; then
    echo "Image ${image}:${version} already published."
  else
    echo "Building image $image:$version..."
    docker build -t "$REGISTRY:$image-$version" "ci/images/$image"
    docker push "$REGISTRY:$image-$version"
  fi

done
