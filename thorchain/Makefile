NAME?=thorchain
ARGS=${NAME} ./thorchain --namespace ${NAME} --create-namespace --set-file global.mnemonic=tmp
BINANCE_TESTNET?=http://testnet-binance.thorchain.info:26657

define generate_mnemonic
	docker run namick/12-words | tr -d '\n' > tmp
endef

mocknet:
	$(call generate_mnemonic)
	@helm upgrade --install ${ARGS} --set global.net=mocknet,global.tag=$${TAG:-mocknet},binance-daemon.service.type.rpc=NodePort,bifrost.binanceStartBlockHeight=1; rm tmp

mocknet-validator:
	$(call generate_mnemonic)
	@helm upgrade --install ${ARGS} --set global.net=mocknet,global.tag=$${TAG:-mocknet} \
		--set binance-daemon.enabled=false \
		--set global.peer=${PEER} \
		--set global.binanceDaemon=http://${PEER}:30656; rm tmp

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

clean:
	@helm delete ${NAME} -n ${NAME}
	@kubectl delete namespace ${NAME}

.PHONY: mnemonic mocknet mocknet-validator testnet testnet-validator testnet-slim testnet-slim-validator mainnet mainnet-validator clean
