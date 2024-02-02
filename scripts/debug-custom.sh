#!/usr/bin/env bash

source ./scripts/core.sh

get_alpine_img() {
  # shellcheck disable=SC2046,SC2312
  # Pull the current pinned alpine/k8s version from thornode's chart.
  yq -r '.global.images.alpineK8s | "alpine/k8s:" + .tag + "@sha256:" + .hash' \
    <"$(dirname $(readlink -f $0))"/../thornode/values.yaml
}

if [[ -z ${NAME} ]]; then
  read -r -p "Namespace: " NAME
fi

K="kubectl -n ${NAME}"

DEPLOYS=$(${K} get deployments --no-headers -o custom-columns=":metadata.name")
DEFAULT=$(echo "${DEPLOYS}" | head -n 1)
menu "${DEFAULT}" ${DEPLOYS}
DEPLOY="${MENU_SELECTED}"

echo "=> Debugging ${DEPLOY} in ${boldgreen}${NAME}${reset}"
confirm

INFO=$(${K} get deploy/"${DEPLOY}" -o json)
DEPLOY_IMAGE=$(echo "${INFO}" | jq '.spec.template.spec.containers[0].image' | tr -d '"')
VOLUMEMOUNT=$(echo "${INFO}" | jq '.spec.template.spec.containers[0].volumeMounts | .[] | select(.name=="data")')
MOUNTPATH=$(echo "${VOLUMEMOUNT}" | jq '.mountPath')

menu alpine alpine ${DEPLOY_IMAGE}
if [[ ${MENU_SELECTED} == "alpine" ]]; then
  MENU_SELECTED="$(get_alpine_img)"
fi
IMAGE="${MENU_SELECTED}"

SPEC=$(
  cat <<EOF
{
  "apiVersion": "v1",
  "spec": {
    "containers": [
      {
        "command": [
          "sh"
        ],
        "name": "debug-${DEPLOY}",
        "stdin": true,
        "tty": true,
        "image": "${IMAGE}",
        "volumeMounts": [${VOLUMEMOUNT}]
      }
    ],
    "volumes": [{"name": "data", "persistentVolumeClaim": {"claimName": "${DEPLOY}"}}]
  }
}
EOF
)

printf "Volume mounted at: %s\n" "${MOUNTPATH}"

${K} scale --replicas=0 deploy/"${DEPLOY}" --timeout=5m
${K} wait --for=delete pods -l app.kubernetes.io/name="${DEPLOY}" --timeout=5m >/dev/null 2>&1 || true
${K} run -it --rm debug-"${DEPLOY}" --restart=Never --image="alpine" --overrides="${SPEC}"
${K} scale --replicas=1 deploy/"${DEPLOY}" --timeout=5m
