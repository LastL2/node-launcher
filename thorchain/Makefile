NAME?=thorchain
ARGS=${NAME} ./thorchain --namespace ${NAME} --create-namespace --set-file global.mnemonic=tmp --render-subchart-notes --wait
BINANCE_TESTNET?=http://testnet-binance.thorchain.info:26657

define generate_mnemonic
	@(kubectl get -n ${NAME} secrets/thor-daemon && kubectl get -n ${NAME} secrets/thor-daemon --template={{.data.mnemonic}} | base64 --decode > tmp) || docker run namick/12-words | tr -d '\n' > tmp
endef

mocknet:
	$(call generate_mnemonic)
	@helm upgrade --install ${ARGS} --set global.net=mocknet,global.tag=$${TAG:-mocknet},binance-daemon.service.type.rpc=NodePort,bifrost.binanceStartBlockHeight=1; rm tmp

mocknet-validator:
	$(call generate_mnemonic)
	@helm upgrade --install ${ARGS} --set global.net=mocknet,global.tag=$${TAG:-mocknet} \
		--set binance-daemon.enabled=false \
		--set global.peer=${PEER} \
		--set global.binanceDaemon=http://${PEER}:30657; rm tmp

testnet:
	$(call generate_mnemonic)
	@helm upgrade --install ${ARGS} --set global.net=testnet,global.tag=$${TAG:-testnet}; rm tmp

testnet-validator:
	$(call generate_mnemonic)
	@helm upgrade --install ${ARGS} --set global.net=testnet,global.tag=$${TAG:-testnet} --set global.peer=${PEER}; rm tmp

testnet-slim:
	$(call generate_mnemonic)
	@helm upgrade --install ${ARGS} --set global.net=testnet,global.tag=$${TAG:-testnet} \
		--set binance-daemon.enabled=false \
		--set global.binanceDaemon=${BINANCE_TESTNET}; rm tmp

testnet-slim-validator:
	$(call generate_mnemonic)
	@helm upgrade --install ${ARGS} --set global.net=testnet,global.tag=$${TAG:-testnet} \
		--set binance-daemon.enabled=false \
		--set global.peer=${PEER} \
		--set global.binanceDaemon=${BINANCE_TESTNET}; rm tmp

mainnet:
	$(call generate_mnemonic)
	@helm upgrade --install ${ARGS}; rm tmp

mainnet-validator:
	$(call generate_mnemonic)
	@helm upgrade --install ${ARGS} --set global.peer=${PEER}; rm tmp

destroy:
	@helm delete ${NAME} -n ${NAME}
	@kubectl delete namespace ${NAME}

status:
	$(eval NODE_IP=$(shell kubectl exec --namespace ${NAME} deploy/thor-daemon -- curl -s http://whatismyip.akamai.com))
	$(eval NODE_ADDRESS=$(shell kubectl exec --namespace ${NAME} deploy/thor-daemon -- ls /root/.thorcli/keyring-THORChain | grep address | awk -F '.' '{print $$1}'))
	$(eval VAULT_ADDRESS=$(shell curl -s ${NODE_IP}:1317/thorchain/pool_addresses | jq -r ".current[0].address"))
	@echo Your THORNode IP: ${NODE_IP}
	@echo Your THORNode address: ${NODE_ADDRESS}
	@echo Vault BNB bond address: ${VAULT_ADDRESS}

.PHONY: mnemonic mocknet mocknet-validator testnet testnet-validator testnet-slim testnet-slim-validator mainnet mainnet-validator destroy
