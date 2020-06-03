include thorchain/Makefile

repo:
	helm repo add stable https://kubernetes-charts.storage.googleapis.com

logs: repo
	helm upgrade elastic ./elastic-operator --install -n elastic-system --create-namespace

metrics: repo
	helm upgrade --install metrics-server stable/metrics-server -n metrics --create-namespace
	helm upgrade --install prometheus stable/prometheus-operator -n metrics --create-namespace -f prometheus/values.yaml --version 8.1.2
