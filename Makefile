include thornode/Makefile

helm:
	@curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

repos:
	@echo Installing Helm repos
	@helm repo add stable https://kubernetes-charts.storage.googleapis.com
	@helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard

tools: install-logs install-metrics install-dashboard

destroy-tools: destroy-logs destroy-metrics destroy-dashboard

install-logs: repos
	@echo Installing Logs Management
	@helm upgrade elastic ./elastic-operator --install -n elastic-system --create-namespace --wait
	@echo Waiting for services to be ready...
	@kubectl wait --for=condition=Ready --all pods -n elastic-system --timeout=5m

destroy-logs:
	@echo Deleting Logs Management
	@helm delete elastic -n elastic-system
	@kubectl delete namespace elastic-system

install-metrics: repos
	@echo Installing Metrics
	@helm upgrade --install metrics-server stable/metrics-server -n prometheus-system --create-namespace --wait -f ./metrics-server/values.yaml
	@helm upgrade --install prometheus stable/prometheus-operator -n prometheus-system --create-namespace --wait -f ./prometheus/values.yaml

destroy-metrics:
	@echo Deleting Metrics
	@helm delete metrics-server -n prometheus-system
	@helm delete prometheus -n prometheus-system
	@kubectl delete namespace prometheus-system

install-dashboard: repos
	@echo Installing Kubernetes Dashboard
	@helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard -n kube-system --wait -f ./kubernetes-dashboard/values.yaml
	@kubectl apply -f ./kubernetes-dashboard/dashboard-admin.yaml

destroy-dashboard:
	@echo Deleting Kubernetes Dashboard
	@helm delete kubernetes-dashboard -n kube-system

kibana:
	@echo User: elastic
	@echo Password: $(shell kubectl -n elastic-system get secret elasticsearch-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode; echo)
	@echo Open your browser at https://localhost:5601
	@kubectl -n elastic-system port-forward service/elasticsearch-kb-http 5601

grafana:
	@echo User: admin
	@echo Password: thorchain
	@echo Open your browser at http://localhost:3000
	@kubectl -n prometheus-system port-forward service/prometheus-grafana 3000:80

prometheus:
	@echo Open your browser at http://localhost:9090
	@kubectl -n prometheus-system port-forward service/prometheus-prometheus-oper-prometheus 9090

dashboard:
	@echo Open your browser at http://localhost:8000
	@kubectl -n kube-system port-forward service/kubernetes-dashboard 8000:443

mocknet-4:
	@helmfile -f helmfiles.d/mocknet-4.yaml sync

destroy-mocknet-4:
	@helmfile -f helmfiles.d/mocknet-4.yaml destroy

mocknet-6:
	@helmfile -f helmfiles.d/mocknet-6.yaml sync

destroy-mocknet-6:
	@helmfile -f helmfiles.d/mocknet-6.yaml destroy

mocknet-10:
	@helmfile -f helmfiles.d/mocknet-10.yaml sync

destroy-mocknet-10:
	@helmfile -f helmfiles.d/mocknet-10.yaml destroy

mocknet-20:
	@helmfile -f helmfiles.d/mocknet-20.yaml sync

destroy-mocknet-20:
	@helmfile -f helmfiles.d/mocknet-20.yaml destroy

mocknet-30:
	@helmfile -f helmfiles.d/mocknet-30.yaml sync

destroy-mocknet-30:
	@helmfile -f helmfiles.d/mocknet-30.yaml destroy

.PHONY: helm repo tools install-logs install-metrics install-dashboard destroy-tools destroy-logs destroy-metrics prometheus grafana kibana dashboard
