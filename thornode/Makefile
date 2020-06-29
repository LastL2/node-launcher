NAME?=thornode
BINANCE_TESTNET?=http://testnet-binance.thorchain.info:26657
MNEMONIC_CMD=kubectl run -n default -it --rm mnemonic --image=registry.gitlab.com/thorchain/thornode --restart=Never --command -- generate | grep MASTER_MNEMONIC= | awk -F= '{print $$NF}'
MNEMONIC_SECRET=thornode-mnemonic
ARGS=${NAME} ./thornode --namespace ${NAME} --create-namespace --set global.mnemonicSecret=${MNEMONIC_SECRET} --wait --timeout 10m

define node_attach
	kubectl exec -it --namespace ${NAME} deploy/thor-daemon -- ${1}
endef

mnemonic:
	@exec ${MNEMONIC_CMD}

create-namespace:
	@echo Creating THORNode Namespace
	@kubectl get ns ${NAME} &> /dev/null || kubectl create ns ${NAME}

create-mnemonic: install-istio create-namespace
	@echo Generating THORNode Mnemonic phrase
	@kubectl get -n ${NAME} secrets/${MNEMONIC_SECRET} &> /dev/null || kubectl -n ${NAME} create secret generic ${MNEMONIC_SECRET} --from-literal='mnemonic=$(shell exec ${MNEMONIC_CMD})'

install-istio:
	@echo Installing Istio
	@type istioctl > /dev/null || (curl -sL https://istio.io/downloadIstioctl | sh - && mv ${HOME}/.istioctl/bin/istioctl /usr/local/bin/)
	@istioctl install -y -w --set profile=minimal

mocknet: install-istio create-mnemonic
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.net=mocknet,global.tag=$${TAG:-mocknet} \
		--set binance-daemon.service.type=LoadBalancer \
		--set bifrost.binanceStartBlockHeight=1

mocknet-validator: install-istio create-mnemonic
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.net=mocknet,global.tag=$${TAG:-mocknet} \
		--set binance-daemon.enabled=false \
		--set global.peer=${PEER} \
		--set global.binanceDaemon=${BINANCE}

testnet: install-istio create-mnemonic
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.net=testnet,global.tag=$${TAG:-testnet}

testnet-validator: install-istio create-mnemonic
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.net=testnet,global.tag=$${TAG:-testnet} --set global.peer=${PEER}

testnet-slim: install-istio create-mnemonic
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.net=testnet,global.tag=$${TAG:-testnet} \
		--set binance-daemon.enabled=false \
		--set global.binanceDaemon=${BINANCE_TESTNET}

testnet-slim-validator: install-istio create-mnemonic
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.net=testnet,global.tag=$${TAG:-testnet} \
		--set binance-daemon.enabled=false \
		--set global.peer=${PEER} \
		--set global.binanceDaemon=${BINANCE_TESTNET}

mainnet: install-istio create-mnemonic
	@echo Installing THORNode
	@helm upgrade --install ${ARGS}

mainnet-validator: install-istio create-mnemonic
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.peer=${PEER}

destroy:
	@echo Deleting THORNode
	@helm delete ${NAME} -n ${NAME}
	@kubectl delete namespace ${NAME}

status:
	@echo THORNode Status:
	@echo IP: $(shell kubectl -n ${NAME} get configmap thor-daemon-external-ip -o jsonpath={.data.externalIP} > .node_ip && cat .node_ip)
	@echo Address: $(shell $(call node_attach,sh -c "echo \$$SIGNER_PASSWD | thorcli keys show \$$SIGNER_NAME -a") > .node_address && cat .node_address)
	@echo Version: $(shell $(call node_attach,sh -c "source /scripts/core.sh;fetch_version"))
	@echo API: http://$(shell cat .node_ip):1317
	@echo RPC: http://$(shell cat .node_ip):$(shell kubectl get -n ${NAME} -o jsonpath="{.spec.ports[?(@.name=='rpc')].port}" services thor-daemon)
	@echo Midgard API: http://$(shell cat .node_ip):8080
	@echo Preflight: $(shell curl -s $(shell cat .node_ip):1317/thorchain/nodeaccount/$(shell cat .node_address)/preflight)
	@echo Vault BNB Bond address: $(shell curl -s $(shell cat .node_ip):1317/thorchain/pool_addresses | jq -r ".current[0].address")
	@rm .node_ip .node_address

midgard:
	@echo Open your browser at http://localhost:8080
	@kubectl -n ${NAME} port-forward service/midgard 8080

shell:
	@$(call node_attach,sh)

set-node-keys:
	@$(call node_attach,sh -c "source /scripts/core.sh;set_node_keys \$$SIGNER_NAME \$$SIGNER_PASSWD localhost")

set-ip-address:
	@$(call node_attach,sh -c "source /scripts/core.sh;set_ip_address \$$SIGNER_NAME \$$SIGNER_PASSWD localhost $(shell kubectl -n ${NAME} get configmap thor-daemon-external-ip -o jsonpath={.data.externalIP})")

.PHONY: mnemonic mocknet mocknet-validator testnet testnet-validator testnet-slim testnet-slim-validator mainnet mainnet-validator destroy midgard status shell mnemonic create-mnemonic set-node-keys set-ip-address
