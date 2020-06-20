include thorchain/Makefile

helm:
	@curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

repo:
	@helm repo add stable https://kubernetes-charts.storage.googleapis.com

logs: repo
	@helm upgrade elastic ./elastic-operator --install -n elastic-system --create-namespace --wait
	@echo Waiting for services to be ready...
	@kubectl wait --for=condition=Ready --all pods -n elastic-system --timeout=5m

destroy-logs:
	@helm delete elastic -n elastic-system
	@kubectl delete namespace elastic-system

kibana:
	@echo "User 'elastic' password:"
	@kubectl -n elastic-system get secret elasticsearch-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode; echo
	@echo Open your browser at https://localhost:5601
	@kubectl -n elastic-system port-forward service/elasticsearch-kb-http 5601

metrics: repo
	@helm upgrade --install metrics-server stable/metrics-server -n prometheus-system --create-namespace --wait
	@helm upgrade --install prometheus stable/prometheus-operator -n prometheus-system --create-namespace --wait -f ./prometheus/values.yaml

grafana:
	@echo "User 'admin' password:"
	@echo prom-operator
	@echo Open your browser at http://localhost:3000
	@kubectl -n prometheus-system port-forward service/prometheus-grafana 3000:80

destroy-metrics:
	@helm delete metrics-server -n prometheus-system
	@helm delete prometheus -n prometheus-system
	@kubectl delete namespace prometheus-system

.PHONY: helm repo logs metrics destroy-logs destroy-metrics
