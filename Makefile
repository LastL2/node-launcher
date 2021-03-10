SHELL:=/bin/bash
VERSION_MAINNET=chaosnet-multichain-0.29.0
VERSION_TESTNET=testnet-multichain-0.30.0
VERSION_MIDGARD_MAINNET=2.0.0-alpha3
VERSION_MIDGARD_TESTNET=2.0.0-alpha3

help: ## Help message
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

helm: ## Install Helm 3 dependency
	@curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

repos: ## Add Helm repositories for dependencies
	@echo Installing Helm repos
	@helm repo add stable https://charts.helm.sh/stable
	@helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard
	@helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	@helm repo add loki https://grafana.github.io/loki/charts
	@helm repo update

tools: install-loki install-metrics install-dashboard ## Intall/Update tools: logs, metrics, Kubernetes dashboard

pull: ## Git pull node-launcher repository
	@git pull origin $(git rev-parse --abbrev-ref HEAD) && sleep 3

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

deploy: update-dependencies ## Deploy a THORNode
	@./scripts/deploy.sh

update: pull update-dependencies ## Update a THORNode to latest version
	@./scripts/update.sh

status: ## Display current status of your THORNode
	@./scripts/status.sh

reset: ## Reset and resync a service from scratch on your THORNode. This command can take a while to sync back to 100%.
	@./scripts/reset.sh

wait-ready: ## Wait for all pods to be in Ready state
	@./scripts/wait-ready.sh

destroy: ## Uninstall current THORNode
	@./scripts/destroy.sh

shell: ## Open a shell for a selected THORNode service
	@./scripts/shell.sh

watch: ## Watch the THORNode pods in real time
	@./scripts/watch.sh

logs: ## Display logs for a selected THORNode service
	@./scripts/logs.sh

restart: ## Restart a selected THORNode service
	@./scripts/restart.sh

set-node-keys: ## Send a set-node-keys transaction to your THORNode
	@./scripts/set-node-keys.sh

set-version: ## Send a set-version transaction to your THORNode
	@./scripts/set-version.sh

set-ip-address: ## Send a set-ip-address transaction to your THORNode
	@./scripts/set-node-keys.sh

telegram-bot: ## Deploy Telegram bot to monitor THORNode
	@./scripts/telegram-bot.sh

destroy-telegram-bot: ## Uninstall Telegram bot to monitor THORNode
	@./scripts/destroy-telegram-bot.sh

destroy-tools: destroy-loki destroy-metrics destroy-dashboard ## Uninstall tools: logs, metrics, Kubernetes dashboard

install-logs: repos ## Install/Update ELK logs management stack
	@echo Installing ELK Logs Management
	@helm upgrade elastic ./elastic-operator --install -n elastic-system --create-namespace --wait
	@echo Waiting for services to be ready...
	@kubectl wait --for=condition=Ready --all pods -n elastic-system --timeout=5m

destroy-logs: ## Uninstall ELK logs management stack
	@echo Deleting ELK Logs Management
	@helm delete elastic -n elastic-system
	@kubectl delete namespace elastic-system

install-loki: repos ## Install/Update Loki logs management stack
	@echo Installing Loki Logs Management
	@helm upgrade loki loki/loki-stack --install -n loki-system --create-namespace --wait -f ./loki/values.yaml
	@echo Waiting for services to be ready...
	@kubectl wait --for=condition=Ready --all pods -n loki-system --timeout=5m

destroy-loki: ## Uninstall Loki logs management stack
	@echo Deleting Loki Logs Management
	@helm delete loki -n loki-system
	@kubectl delete namespace loki-system

install-metrics: repos ## Install/Update metrics management stack
	@echo Installing Metrics
	@kubectl get svc -A | grep -q metrics-server || helm upgrade --install metrics-server stable/metrics-server -n prometheus-system --create-namespace --wait -f ./metrics-server/values.yaml
	@helm upgrade --install prometheus prometheus-community/kube-prometheus-stack -n prometheus-system --create-namespace --wait -f ./prometheus/values.yaml

destroy-metrics: ## Uninstall metrics management stack
	@echo Deleting Metrics
	@kubectl get svc -n prometheus-system metrics-server --ignore-not-found > /dev/null 2>&1 || helm delete metrics-server -n prometheus-system
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

install-dashboard: repos ## Install/Update Kubernetes dashboard
	@echo Installing Kubernetes Dashboard
	@helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard -n kube-system --wait -f ./kubernetes-dashboard/values.yaml
	@kubectl apply -f ./kubernetes-dashboard/dashboard-admin.yaml

destroy-dashboard: ## Uninstall Kubernetes dashboard
	@echo Deleting Kubernetes Dashboard
	@helm delete kubernetes-dashboard -n kube-system

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

.PHONY: help helm repo pull tools install-logs install-metrics install-dashboard destroy-tools destroy-logs destroy-metrics prometheus grafana kibana dashboard alert-manager mnemonic update-dependencies reset restart pods deploy update destroy status shell watch logs set-node-keys set-ip-address set-version telegram-bot destroy-telegram-bot
.EXPORT_ALL_VARIABLES:
