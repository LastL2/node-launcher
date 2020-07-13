NAME?=thornode
BINANCE_TESTNET?=http://testnet-binance.thorchain.info:26657
MNEMONIC_CMD=kubectl run -n ${NAME} -it --rm mnemonic --image=registry.gitlab.com/thorchain/thornode --restart=Never --command -- generate | grep MASTER_MNEMONIC= | awk -F= '{print $$NF}'
MNEMONIC_SECRET=thornode-mnemonic
ARGS=${NAME} ./thornode -n ${NAME} --create-namespace --set global.mnemonicSecret=${MNEMONIC_SECRET} --wait --timeout 10m
THORD_CMD=kubectl exec -it --namespace ${NAME} deploy/thor-daemon --

mnemonic:
	@exec ${MNEMONIC_CMD}

create-namespace:
	@echo Creating THORNode Namespace
	@kubectl get ns ${NAME} &> /dev/null || kubectl create ns ${NAME}

create-mnemonic: create-namespace
	@echo Generating THORNode Mnemonic phrase
	@kubectl get -n ${NAME} secrets/${MNEMONIC_SECRET} &> /dev/null || kubectl -n ${NAME} create secret generic ${MNEMONIC_SECRET} --from-literal='mnemonic=$(shell exec ${MNEMONIC_CMD})'

mocknet: create-mnemonic
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} \
		--set global.net=mocknet,global.tag=$${TAG:-mocknet},midgard.image.tag=mocknet \
		--set binance-daemon.service.type=LoadBalancer \
		--set bifrost.binanceStartBlockHeight=1

mocknet-validator: create-mnemonic
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} \
		--set global.net=mocknet,global.tag=$${TAG:-mocknet},midgard.image.tag=mocknet \
		--set binance-daemon.enabled=false \
		--set global.peer=${PEER} \
		--set global.binanceDaemon=${BINANCE}

testnet: create-mnemonic
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.net=testnet,global.tag=$${TAG:-testnet},midgard.image.tag=testnet

testnet-validator: create-mnemonic
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.net=testnet,global.tag=$${TAG:-testnet},midgard.image.tag=testnet,global.peer=${PEER}

testnet-slim: create-mnemonic
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.net=testnet,global.tag=$${TAG:-testnet},midgard.image.tag=testnet \
		--set binance-daemon.enabled=false \
		--set global.binanceDaemon=${BINANCE_TESTNET}

testnet-slim-validator: create-mnemonic
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.net=testnet,global.tag=$${TAG:-testnet},midgard.image.tag=testnet \
		--set binance-daemon.enabled=false \
		--set global.peer=${PEER} \
		--set global.binanceDaemon=${BINANCE_TESTNET}

mainnet: create-mnemonic
	@echo Installing THORNode
	@helm upgrade --install ${ARGS}

mainnet-validator: create-mnemonic
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.peer=${PEER}

destroy:
	@echo Deleting THORNode
	@helm delete ${NAME} -n ${NAME}
	@kubectl delete namespace ${NAME}

status:
	@exec ${THORD_CMD} /kube-scripts/node-status.sh

midgard:
	@echo Open your browser at http://localhost:8080
	@kubectl -n ${NAME} port-forward service/midgard 8080

shell:
	@exec ${THORD_CMD} sh

logs:
	@kubectl logs -f -n ${NAME} deploy/thor-daemon

set-node-keys:
	@exec ${THORD_CMD} /kube-scripts/set-node-keys.sh > /dev/null
	@echo THORNode Keys updated

set-version:
	@exec ${THORD_CMD} /kube-scripts/set-version.sh > /dev/null
	@echo THORNode version updated

set-ip-address:
	@exec ${THORD_CMD} /kube-scripts/set-ip-address.sh $(shell kubectl -n ${NAME} get configmap thor-daemon-external-ip -o jsonpath={.data.externalIP}) > /dev/null
	@echo THORNode IP address updated

.PHONY: mnemonic mocknet mocknet-validator testnet testnet-validator testnet-slim testnet-slim-validator mainnet mainnet-validator destroy midgard status shell mnemonic create-mnemonic set-node-keys set-ip-address
