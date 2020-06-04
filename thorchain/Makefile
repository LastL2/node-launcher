NAME?=thorchain
ARGS=${NAME} ./thorchain --namespace ${NAME} --create-namespace --set-file global.mnemonic=tmp

mnemonic:
	$(shell docker run namick/12-words | tr -d '\n' > tmp)

mocknet: mnemonic
	@helm upgrade --install ${ARGS} --set global.net=mocknet,global.tag=$${TAG:-mocknet},binance-daemon.service.type.rpc=NodePort; rm tmp

testnet: mnemonic
	@helm upgrade --install ${ARGS} --set global.net=testnet,global.tag=$${TAG:-testnet}; rm tmp

mainnet: mnemonic
	@helm upgrade --install ${ARGS}; rm tmp

mocknet-validator: mnemonic
	@helm upgrade --install ${ARGS} --set global.net=mocknet,global.tag=$${TAG:-mocknet} \
		--set binance-daemon.enabled=false \
		--set global.peer=139.180.169.102 \
		--set global.binanceDaemon=http://139.180.169.102:30779; rm tmp

clean:
	@helm delete ${NAME} -n ${NAME}
	@kubectl delete namespace ${NAME}
