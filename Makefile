include thornode/Makefile

help: ## Help message
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

helm: ## Install Helm 3 dependency
	@curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

repos: ## Add Helm repositories for dependencies
	@echo Installing Helm repos
	@helm repo add stable https://charts.helm.sh/stable
	@helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard
	@helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	@helm repo update

tools: install-logs install-metrics install-dashboard ## Intall/Update tools: logs, metrics, Kubernetes dashboard

pull: ## Git pull node-launcher repository
	@git pull origin master && sleep 3

destroy-tools: destroy-logs destroy-metrics destroy-dashboard ## Uninstall tools: logs, metrics, Kubernetes dashboard

install-logs: repos ## Install/Update logs management stack
	@echo Installing Logs Management
	@helm upgrade elastic ./elastic-operator --install -n elastic-system --create-namespace --wait
	@echo Waiting for services to be ready...
	@kubectl wait --for=condition=Ready --all pods -n elastic-system --timeout=5m

destroy-logs: ## Uninstall logs management stack
	@echo Deleting Logs Management
	@helm delete elastic -n elastic-system
	@kubectl delete namespace elastic-system

install-metrics: repos ## Install/Update metrics management stack
	@echo Installing Metrics
	@kubectl get svc -A | grep -q metrics-server || helm upgrade --install metrics-server stable/metrics-server -n prometheus-system --create-namespace --wait -f ./metrics-server/values.yaml
	@helm upgrade --install prometheus prometheus-community/kube-prometheus-stack -n prometheus-system --create-namespace --wait -f ./prometheus/values.yaml

destroy-metrics: ## Uninstall metrics management stack
	@echo Deleting Metrics
	@kubectl get svc -n prometheus-system metrics-server > /dev/null 2>&1 || helm delete metrics-server -n prometheus-system
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

mocknet-4: ## Install/Update a Mocknet development environment with 4 THORNodes
	@helmfile -f helmfiles.d/mocknet-4.yaml sync

destroy-mocknet-4: ## Uninstall a Mocknet development environment with 4 THORNodes
	@helmfile -f helmfiles.d/mocknet-4.yaml destroy

mocknet-6: ## Install/Update a Mocknet development environment with 6 THORNodes
	@helmfile -f helmfiles.d/mocknet-6.yaml sync

destroy-mocknet-6: ## Uninstall a Mocknet development environment with 6 THORNodes
	@helmfile -f helmfiles.d/mocknet-6.yaml destroy

mocknet-10: ## Install/Update a Mocknet development environment with 10 THORNodes
	@helmfile -f helmfiles.d/mocknet-10.yaml sync

destroy-mocknet-10: ## Uninstall a Mocknet development environment with 10 THORNodes
	@helmfile -f helmfiles.d/mocknet-10.yaml destroy

mocknet-20: ## Install/Update a Mocknet development environment with 20 THORNodes
	@helmfile -f helmfiles.d/mocknet-20.yaml sync

destroy-mocknet-20: ## Uninstall a Mocknet development environment with 20 THORNodes
	@helmfile -f helmfiles.d/mocknet-20.yaml destroy

mocknet-30: ## Install/Update a Mocknet development environment with 30 THORNodes
	@helmfile -f helmfiles.d/mocknet-30.yaml sync

destroy-mocknet-30: ## Uninstall a Mocknet development environment with 30 THORNodes
	@helmfile -f helmfiles.d/mocknet-30.yaml destroy

.PHONY: help helm repo pull tools install-logs install-metrics install-dashboard destroy-tools destroy-logs destroy-metrics prometheus grafana kibana dashboard alert-manager mocknet-4 destroy-mocknet-4 mocknet-6 destroy-mocknet-6 mocknet-10 destroy-mocknet-10 mocknet-20 destroy-mocknet-20 mocknet-30 destroy-mocknet-30
