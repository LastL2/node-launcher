NAME?=thornode
ARGS=${NAME} ./thornode --namespace ${NAME} --create-namespace --set-file global.mnemonic=tmp --render-subchart-notes --wait --timeout 10m
BINANCE_TESTNET?=http://testnet-binance.thorchain.info:26657
MNEMONIC_IMAGE=registry.gitlab.com/thorchain/thornode

define generate_mnemonic
	kubectl run -n default --attach --rm mnemonic --image=${MNEMONIC_IMAGE} --restart=Never --command -- generate | grep MASTER_MNEMONIC= | awk -F= '{print $$NF}'
endef

define node_attach
	kubectl exec -it --namespace ${NAME} deploy/thor-daemon -- ${1}
endef

mnemonic:
	@$(call generate_mnemonic)

check-mnemonic:
	@(kubectl get -n ${NAME} secrets/thor-daemon &> /dev/null && kubectl get -n ${NAME} secrets/thor-daemon --template={{.data.mnemonic}} | base64 --decode > tmp)\
		|| $(call generate_mnemonic) > tmp

install-istio:
	@echo Installing Istio
	@type istioctl > /dev/null || (curl -sL https://istio.io/downloadIstioctl | sh - && mv ${HOME}/.istioctl/bin/istioctl /usr/local/bin/)
	@istioctl install -y -w --set profile=minimal

mocknet: install-istio check-mnemonic
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.net=mocknet,global.tag=$${TAG:-mocknet} \
		--set binance-daemon.service.type=LoadBalancer \
		--set bifrost.binanceStartBlockHeight=1
	@rm tmp

mocknet-validator: install-istio check-mnemonic
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.net=mocknet,global.tag=$${TAG:-mocknet} \
		--set binance-daemon.enabled=false \
		--set global.peer=${PEER} \
		--set global.binanceDaemon=${BINANCE}
	@rm tmp

testnet: install-istio check-mnemonic
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.net=testnet,global.tag=$${TAG:-testnet}
	@rm tmp

testnet-validator: install-istio check-mnemonic
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.net=testnet,global.tag=$${TAG:-testnet} --set global.peer=${PEER}
	@rm tmp

testnet-slim: install-istio check-mnemonic
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.net=testnet,global.tag=$${TAG:-testnet} \
		--set binance-daemon.enabled=false \
		--set global.binanceDaemon=${BINANCE_TESTNET}
	@rm tmp

testnet-slim-validator: install-istio check-mnemonic
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.net=testnet,global.tag=$${TAG:-testnet} \
		--set binance-daemon.enabled=false \
		--set global.peer=${PEER} \
		--set global.binanceDaemon=${BINANCE_TESTNET}
	@rm tmp

mainnet: install-istio check-mnemonic
	@echo Installing THORNode
	@helm upgrade --install ${ARGS}
	@rm tmp

mainnet-validator: install-istio check-mnemonic
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.peer=${PEER}
	@rm tmp

destroy:
	@echo Deleting THORNode
	@helm delete ${NAME} -n ${NAME}
	@kubectl delete namespace ${NAME}

status:
	@echo Your THORNode IP: $(shell kubectl get configmap thor-daemon-external-ip -o jsonpath={.data.externalIP} > .node_ip && cat .node_ip)
	@echo Access THORNode API: http://$(shell cat .node_ip):1317
	@echo Access THORNode RPC: http://$(shell cat .node_ip):$(shell kubectl get -n ${NAME} -o jsonpath="{.spec.ports[?(@.name=='rpc')].port}" services thor-daemon)
	@echo Access Midgard API: http://$(shell cat .node_ip):8080
	@echo Your THORNode version: $(shell $(call node_attach,sh -c "source /scripts/core.sh;fetch_version"))
	@echo Your THORNode address: $(shell $(call node_attach,sh -c "echo \$$SIGNER_PASSWD | thorcli keys show \$$SIGNER_NAME -a"))
	@echo Vault BNB Bond address: $(shell $(call node_attach,curl -s $(shell cat .node_ip):1317/thorchain/pool_addresses | jq -r ".current[0].address"))
	@rm .node_ip

midgard:
	@echo Open your browser at http://localhost:8080
	@kubectl -n ${NAME} port-forward service/midgard 8080

shell:
	@$(call node_attach,sh)

set-node-keys:
	@$(call node_attach,sh -c "source /scripts/core.sh;set_node_keys \$$SIGNER_NAME \$$SIGNER_PASSWD localhost")

set-ip-address:
	@$(call node_attach,sh -c "source /scripts/core.sh;set_ip_address \$$SIGNER_NAME \$$SIGNER_PASSWD localhost")

.PHONY: mnemonic mocknet mocknet-validator testnet testnet-validator testnet-slim testnet-slim-validator mainnet mainnet-validator destroy midgard status shell mnemonic check-mnemonic set-node-keys set-ip-address
