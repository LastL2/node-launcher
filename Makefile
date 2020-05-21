include thorchain/Makefile

logs:
	helm upgrade elastic ./elastic-operator --install -n elastic-system --create-namespace

metrics:
	helm upgrade prometheus stable/prometheus-operator --install -n prometheus --create-namespace -f prometheus/values.yaml
