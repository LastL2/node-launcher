SHELL:=/bin/bash

help: ## Help message
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

helm: ## Install Helm 3 dependency
	@curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

helm-plugins: ## Install Helm plugins
	@helm plugin install https://github.com/databus23/helm-diff

repos: ## Add Helm repositories for dependencies
	@echo "=> Installing Helm repos"
	@helm repo add grafana https://grafana.github.io/helm-charts
	@helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard
	@helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	@helm repo update
	@echo

tools: install-prometheus install-loki install-metrics install-dashboard ## Intall/Update Prometheus/Grafana, Loki, Metrics Server, Kubernetes dashboard

pull: ## Git pull node-launcher repository
	@git clean -df
	@git pull origin $(shell git rev-parse --abbrev-ref HEAD)

update-dependencies:
	@echo "=> Updating Helm chart dependencies"
	@helm dependencies update ./thornode-stack
	@echo

mnemonic: ## Retrieve and display current mnemonic for backup from your THORNode
	@./scripts/mnemonic.sh

password: ## Retrieve and display current password for backup from your THORNode
	@./scripts/password.sh

pods: ## Get THORNode Kubernetes pods
	@./scripts/pods.sh

install: pull update-dependencies ## Deploy a THORNode
	@./scripts/install.sh

update: pull update-dependencies ## Update a THORNode to latest version
	@./scripts/update.sh

status: ## Display current status of your THORNode
	@./scripts/status.sh

reset: ## Reset and resync a service from scratch on your THORNode. This command can take a while to sync back to 100%.
	@./scripts/reset.sh

backup: ## Backup specific files from either thornode of bifrost service of a THORNode.
	@./scripts/backup.sh

restore-backup: ## Restore backup specific files from either thornode of bifrost service of a THORNode.
	@./scripts/restore-backup.sh

snapshot: ## Snapshot a volume for a specific THORNode service.
	@./scripts/snapshot.sh

restore-snapshot: ## Restore a volume for a specific THORNode service from a snapshot.
	@./scripts/restore-snapshot.sh

wait-ready: ## Wait for all pods to be in Ready state
	@./scripts/wait-ready.sh

destroy: ## Uninstall current THORNode
	@./scripts/destroy.sh

export-state: ## Export chain state
	@./scripts/export-state.sh

hard-fork: ## Hard fork chain
	@./scripts/hard-fork.sh

shell: ## Open a shell for a selected THORNode service
	@./scripts/shell.sh

debug: ## Open a shell for THORNode service mounting volume to debug
	@./scripts/debug.sh

watch: ## Watch the THORNode pods in real time
	@./scripts/watch.sh

logs: ## Display logs for a selected THORNode service
	@./scripts/logs.sh

restart: ## Restart a selected THORNode service
	@./scripts/restart.sh

halt: ## Halt a selected THORNode service
	@./scripts/halt.sh

set-node-keys: ## Send a set-node-keys transaction to your THORNode
	@./scripts/set-node-keys.sh

set-version: ## Send a set-version transaction to your THORNode
	@./scripts/set-version.sh

set-ip-address: ## Send a set-ip-address transaction to your THORNode
	@./scripts/set-ip-address.sh

relay: ## Send a message that is relayed to a public Discord channel
	@./scripts/relay.sh

pause: ## Send a pause-chain transaction to your THORNode
	@./scripts/pause.sh

resume: ## Send a resume-chain transaction to your THORNode
	@./scripts/resume.sh

telegram-bot: ## Deploy Telegram bot to monitor THORNode
	@./scripts/telegram-bot.sh

destroy-telegram-bot: ## Uninstall Telegram bot to monitor THORNode
	@./scripts/destroy-telegram-bot.sh

destroy-tools: destroy-prometheus destroy-loki destroy-dashboard ## Uninstall Prometheus/Grafana, Loki, Kubernetes dashboard

install-elk: repos ## Install/Update ELK logs management stack
	@echo "=> Installing ELK Logs Management"
	@helm upgrade elastic ./elastic-operator --install -n elastic-system --create-namespace --wait
	@echo Waiting for services to be ready...
	@kubectl wait --for=condition=Ready --all pods -n elastic-system --timeout=5m
	@echo

destroy-elk: ## Uninstall ELK logs management stack
	@echo "=> Deleting ELK Logs Management"
	@helm delete elastic -n elastic-system
	@kubectl delete namespace elastic-system
	@echo

install-loki: repos ## Install/Update Loki logs management stack
	@echo "=> Installing Loki Logs Management"
	@helm upgrade loki grafana/loki-stack --install -n loki-system --create-namespace --wait -f ./loki/values.yaml
	@echo Waiting for services to be ready...
	@kubectl wait --for=condition=Ready --all pods -n loki-system --timeout=5m
	@echo

destroy-loki: ## Uninstall Loki logs management stack
	@echo "=> Deleting Loki Logs Management"
	@helm delete loki -n loki-system
	@kubectl delete namespace loki-system
	@echo

install-prometheus: repos ## Install/Update Prometheus/Grafana stack
	@echo "=> Installing Prometheus/Grafana Stack"
	@helm upgrade --install prometheus prometheus-community/kube-prometheus-stack -n prometheus-system --create-namespace --wait -f ./prometheus/values.yaml
	@echo

destroy-prometheus: ## Uninstall Prometheus/Grafana stack
	@echo "=> Deleting Prometheus/Grafana Stack"
	@helm delete prometheus -n prometheus-system
	@kubectl delete crd alertmanagerconfigs.monitoring.coreos.com
	@kubectl delete crd alertmanagers.monitoring.coreos.com
	@kubectl delete crd podmonitors.monitoring.coreos.com
	@kubectl delete crd probes.monitoring.coreos.com
	@kubectl delete crd prometheuses.monitoring.coreos.com
	@kubectl delete crd prometheusrules.monitoring.coreos.com
	@kubectl delete crd servicemonitors.monitoring.coreos.com
	@kubectl delete crd thanosrulers.monitoring.coreos.com
	@kubectl delete namespace prometheus-system
	@echo

install-metrics: repos ## Install/Update Metrics Server
	@echo "=> Installing Metrics"
	@kubectl get svc -A | grep -q metrics-server || kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
	@echo

destroy-metrics: ## Uninstall Metrics Server
	@echo "=> Deleting Metrics"
	@kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
	@echo

install-dashboard: repos ## Install/Update Kubernetes dashboard
	@echo "=> Installing Kubernetes Dashboard"
	@helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard -n kube-system --wait -f ./kubernetes-dashboard/values.yaml
	@kubectl apply -f ./kubernetes-dashboard/dashboard-admin.yaml
	@echo

destroy-dashboard: ## Uninstall Kubernetes dashboard
	@echo "=> Deleting Kubernetes Dashboard"
	@helm delete kubernetes-dashboard -n kube-system
	@echo

kibana: ## Access Kibana UI through port-forward locally
	@echo User: elastic
	@echo Password: $(shell kubectl -n elastic-system get secret elasticsearch-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode; echo)
	@echo Open your browser at https://localhost:5601
	@kubectl -n elastic-system port-forward service/elasticsearch-kb-http 5601

grafana: ## Access Grafana UI through port-forward locally
	@echo User: admin
	@echo Password: thorchain
	@echo Open your browser at http://localhost:3000
	@kubectl -n prometheus-system port-forward service/prometheus-grafana 3000:80

prometheus: ## Access Prometheus UI through port-forward locally
	@echo Open your browser at http://localhost:9090
	@kubectl -n prometheus-system port-forward service/prometheus-kube-prometheus-prometheus 9090

alert-manager: ## Access Alert-Manager UI through port-forward locally
	@echo Open your browser at http://localhost:9093
	@kubectl -n prometheus-system port-forward service/prometheus-kube-prometheus-alertmanager 9093

dashboard: ## Access Kubernetes Dashboard UI through port-forward locally
	@echo Open your browser at http://localhost:8000
	@kubectl -n kube-system port-forward service/kubernetes-dashboard 8000:443

.PHONY: help helm repo pull tools install-elk install-loki install-prometheus install-metrics install-dashboard export-state hard-fork destroy-tools destroy-elk destroy-loki destroy-prometheus destroy-metrics prometheus grafana kibana dashboard alert-manager mnemonic update-dependencies reset restart pods deploy update destroy status shell watch logs set-node-keys set-ip-address set-version pause resume telegram-bot destroy-telegram-bot
.EXPORT_ALL_VARIABLES:
