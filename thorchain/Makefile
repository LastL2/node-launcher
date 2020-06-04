NAME?=thorchain
ARGS=${NAME} ./thorchain --namespace ${NAME} --create-namespace --set-file global.mnemonic=tmp

mnemonic:
	$(shell docker run namick/12-words | tr -d '\n' > tmp)

mocknet: mnemonic
	@helm upgrade --install ${ARGS} --set global.net=$${NET:-mocknet} --set global.tag=$${TAG:-mocknet}; rm tmp

testnet: mnemonic
	@helm upgrade --install ${ARGS} --set global.net=$${NET:-testnet} --set global.tag=$${TAG:-testnet}; rm tmp

mainnet: mnemonic
	@helm upgrade --install ${ARGS}; rm tmp

clean:
	@helm delete ${NAME} -n ${NAME}
	@kubectl delete namespace ${NAME}
