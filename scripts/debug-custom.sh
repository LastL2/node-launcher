#!/usr/bin/env bash

source ./scripts/core.sh

if [[ -z ${NAME} ]]; then
  read -r -p "Namespace: " NAME
fi

DEPLOYS=$(kubectl get -n "${NAME}" deployments --no-headers -o custom-columns=":metadata.name")
DEFAULT=$(echo "${DEPLOYS}" | head -n 1)
# trunk-ignore(shellcheck/SC2086)
menu "${DEFAULT}" ${DEPLOYS}
DEPLOY="${MENU_SELECTED}"

echo "=> Debugging ${DEPLOY} in ${boldgreen}${NAME}${reset}"
confirm

INFO=$(kubectl -n "${NAME}" get deploy/"${DEPLOY}" -o json)
DEPLOY_IMAGE=$(echo "${INFO}" | jq '.spec.template.spec.containers[0].image' | tr -d '"')
VOLUMEMOUNT=$(echo "${INFO}" | jq '.spec.template.spec.containers[0].volumeMounts | .[] | select(.name=="data")')
MOUNTPATH=$(echo "${VOLUMEMOUNT}" | jq '.mountPath')

# trunk-ignore(shellcheck/SC2086)
menu alpine alpine ${DEPLOY_IMAGE}
if [[ ${MENU_SELECTED} == "alpine" ]]; then
  MENU_SELECTED="alpine/k8s:1.25.16@sha256:7480dd21404b26776642a286395db36310a83f8f93ae3393692d5c1e15a5e16a"
fi
IMAGE="${MENU_SELECTED}"

SPEC="
{
  \"apiVersion\": \"v1\",
  \"spec\": {
    \"containers\": [
      {
        \"command\": [
          \"sh\"
        ],
        \"name\": \"debug-${DEPLOY}\",
        \"stdin\": true,
        \"tty\": true,
        \"image\": \"${IMAGE}\",
        \"volumeMounts\": [${VOLUMEMOUNT}]
      }
    ],
    \"volumes\": [{\"name\": \"data\", \"persistentVolumeClaim\": {\"claimName\": \"${DEPLOY}\"}}]
  }
}"

printf "Volume mounted at: %s\n" "${MOUNTPATH}"

kubectl scale -n "${NAME}" --replicas=0 deploy/"${DEPLOY}" --timeout=5m
kubectl wait --for=delete pods -l app.kubernetes.io/name="${DEPLOY}" -n "${NAME}" --timeout=5m >/dev/null 2>&1 || true
kubectl run -n "${NAME}" -it --rm debug-"${DEPLOY}" --restart=Never --image="alpine" --overrides="${SPEC}"
kubectl scale -n "${NAME}" --replicas=1 deploy/"${DEPLOY}" --timeout=5m
