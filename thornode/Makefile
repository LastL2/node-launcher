NAME?=thornode
BINANCE_TESTNET?=http://testnet-binance.thorchain.info:26657
MNEMONIC_CMD=kubectl run -n ${NAME} -it --rm mnemonic --image=registry.gitlab.com/thorchain/thornode --restart=Never --command -- generate | grep MASTER_MNEMONIC= | awk -F= '{print $$NF}'
MNEMONIC_SECRET=thornode-mnemonic
ARGS=${NAME} ./thornode -n ${NAME} --create-namespace --set global.mnemonicSecret=${MNEMONIC_SECRET} --wait --timeout 10m
THORD_CMD=kubectl exec -it --namespace ${NAME} deploy/thor-daemon --
SEED_TESTNET?=$(shell curl -s https://testnet-seed.thorchain.info/ | sed 's/\["\(.*\)"\]/\1/')

mnemonic:
	@exec ${MNEMONIC_CMD}

create-namespace:
	@echo Creating THORNode Namespace
	@kubectl get ns ${NAME} > /dev/null 2>&1 || kubectl create ns ${NAME}

create-mnemonic: create-namespace
	@echo Generating THORNode Mnemonic phrase
	@kubectl get -n ${NAME} secrets/${MNEMONIC_SECRET} > /dev/null 2>&1 || kubectl -n ${NAME} create secret generic ${MNEMONIC_SECRET} --from-literal='mnemonic=$(shell exec ${MNEMONIC_CMD})'

update-dependencies:
	@helm dependencies update ./thornode

mocknet-genesis: create-mnemonic update-dependencies
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} \
		--set global.net=mocknet,global.tag=$${TAG:-mocknet},midgard.image.tag=mocknet \
		--set binance-daemon.service.type=LoadBalancer \
		--set bifrost.binanceStartBlockHeight=1

mocknet-validator: create-mnemonic update-dependencies
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} \
		--set global.net=mocknet,global.tag=$${TAG:-mocknet},midgard.image.tag=mocknet \
		--set binance-daemon.enabled=false \
		--set global.peer=${PEER} \
		--set global.binanceDaemon=${BINANCE}

testnet-genesis: create-mnemonic update-dependencies
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.net=testnet,global.tag=$${TAG:-testnet},midgard.image.tag=testnet

testnet-validator: create-mnemonic update-dependencies
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.net=testnet,global.tag=$${TAG:-testnet},midgard.image.tag=testnet,global.peer=${SEED_TESTNET}

mainnet-genesis: create-mnemonic update-dependencies
	@echo Installing THORNode
	@helm upgrade --install ${ARGS}

mainnet-validator: create-mnemonic update-dependencies
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

logs-binance:
	@kubectl logs -f -n ${NAME} deploy/binance-daemon

set-node-keys:
	@exec ${THORD_CMD} /kube-scripts/set-node-keys.sh > /dev/null
	@echo THORNode Keys updated

set-version:
	@exec ${THORD_CMD} /kube-scripts/set-version.sh > /dev/null
	@echo THORNode version updated

set-ip-address:
	@exec ${THORD_CMD} /kube-scripts/set-ip-address.sh $(shell kubectl -n ${NAME} get configmap thor-gateway-external-ip -o jsonpath={.data.externalIP}) > /dev/null
	@echo THORNode IP address updated

.PHONY: mnemonic mocknet-genesis mocknet-validator testnet-genesis testnet-validator mainnet-genesis mainnet-validator destroy midgard status shell mnemonic create-mnemonic set-node-keys set-ip-address
