include thorchain/Makefile

helm:
	@curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

repo:
	@helm repo add stable https://kubernetes-charts.storage.googleapis.com

logs: repo
	@helm upgrade elastic ./elastic-operator --install -n elastic-system --create-namespace

clean-logs:
	@helm delete elastic -n elastic-system
	@kubectl delete namespace elastic-system

kibana:
	@echo User "elastic" password:
	@kubectl -n elastic-system get secret elasticsearch-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode; echo
	@echo Open your browser at https://localhost:5601
	@kubectl -n elastic-system port-forward service/elasticsearch-kb-http 5601 --address 0.0.0.0

metrics: repo
	@helm upgrade --install metrics-server stable/metrics-server -n metrics --create-namespace
	@helm upgrade --install prometheus stable/prometheus-operator -n metrics --create-namespace

grafana:
	@echo User "admin" password:
	@echo prom-operator
	@echo Open your browser at https://localhost:8080
	@kubectl -n metrics port-forward service/prometheus-grafana 8080:80 --address 0.0.0.0

clean-metrics:
	@helm delete metrics-server -n metrics
	@helm delete prometheus -n metrics

.PHONY: helm repo logs metrics
