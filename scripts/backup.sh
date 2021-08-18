#!/usr/bin/env bash

source ./scripts/core.sh

get_node_info_short

if ! node_exists; then
  die "No existing THORNode found, make sure this is the correct name"
fi

echo "=> Select a THORNode service to backup"
menu thornode thornode bifrost
SERVICE=$MENU_SELECTED

if ! kubectl -n "$NAME" get pvc "$SERVICE" >/dev/null 2>&1; then
  warn "Volume $SERVICE not found"
  echo
  exit 0
fi

if [ "$SERVICE" = "bifrost" ]; then
  SPEC="
  {
    \"apiVersion\": \"v1\",
    \"spec\": {
      \"containers\": [
        {
          \"command\": [
            \"sh\",
            \"-c\",
            \"sleep 300\"
          ],
          \"name\": \"backup-$SERVICE\",
          \"image\": \"busybox:1.33\",
          \"volumeMounts\": [
            {\"mountPath\": \"/root/.thornode\", \"name\": \"data\", \"subPath\": \"thornode\"},
            {\"mountPath\": \"/var/data/bifrost\", \"name\": \"data\", \"subPath\": \"data\"}
          ]
        }
      ],
      \"volumes\": [{\"name\": \"data\", \"persistentVolumeClaim\": {\"claimName\": \"$SERVICE\"}}]
    }
  }"
else
  SPEC="
  {
    \"apiVersion\": \"v1\",
    \"spec\": {
      \"containers\": [
        {
          \"command\": [
            \"sh\",
            \"-c\",
            \"sleep 300\"
          ],
          \"name\": \"backup-$SERVICE\",
          \"image\": \"busybox:1.33\",
          \"volumeMounts\": [{\"mountPath\": \"/root\", \"name\":\"data\"}]
        }
      ],
      \"volumes\": [{\"name\": \"data\", \"persistentVolumeClaim\": {\"claimName\": \"$SERVICE\"}}]
    }
  }"

fi

echo
echo "=> Backing up service $boldgreen$SERVICE$reset from THORNode in $boldgreen$NAME$reset"
confirm

POD="deploy/$SERVICE"
if (kubectl get pod -n "$NAME" -l "app.kubernetes.io/name=$SERVICE" 2>&1 | grep "No resources found") >/dev/null 2>&1; then
  kubectl run -n "$NAME" "backup-$SERVICE" --restart=Never --image="busybox:1.33" --overrides="$SPEC"
  kubectl wait --for=condition=ready pods "backup-$SERVICE" -n "$NAME" --timeout=5m >/dev/null 2>&1
  POD="pod/backup-$SERVICE"
fi

DATE=$(date +%s)
mkdir -p "backups/$SERVICE"
if [ "$SERVICE" = "bifrost" ]; then
  kubectl exec -it -n "$NAME" "$POD" -- sh -c "cd /root/.thornode && tar cf \"$SERVICE-$DATE.tar\" localstate-*.json"
else
  kubectl exec -it -n "$NAME" "$POD" -- sh -c "cd /root/.thornode && tar cf \"$SERVICE-$DATE.tar\" config"
fi
kubectl exec -n "$NAME" "$POD" -- sh -c "cd /root/.thornode && tar cf - \"$SERVICE-$DATE.tar\"" | tar xf - -C "$PWD/backups/$SERVICE"

if (kubectl get pod -n "$NAME" -l "app.kubernetes.io/name=$SERVICE" 2>&1 | grep "No resources found") >/dev/null 2>&1; then
  kubectl delete pod --now=true -n "$NAME" "backup-$SERVICE"
fi

echo "Backup available in path ./backups/$SERVICE"
