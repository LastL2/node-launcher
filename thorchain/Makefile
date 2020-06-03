mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
path := $(dir $(mkfile_path))

mocknet:
	$(shell docker run namick/12-words | tr -d '\n' | base64 > tmp)
	helm upgrade --install mocknet thorchain -n mocknet --create-namespace \
		--set global.net=mocknet \
		--set global.tag=mocknet \
		--set-file global.mnemonic=tmp \
		--dry-run
	@rm tmp

testnet:
	helm upgrade --install testnet ./thorchain -n testnet --create-namespace --set global.net=testnet,global.tag=testnet --dry-run

mainnet:
	MNEMONIC=${MNEMONIC:-$(docker run namick/12-words)}
	echo ${MNEMONIC}
	helm upgrade --install mainnet ./thorchain -n mainnet --create-namespace --set global.mnemonic=${MNEMONIC} --dry-run

validator:
	@NET=mocknet TAG=mocknet ${path}/deploy.sh

3-mocknet:
	@NET=mocknet NODES=4 TAG=mocknet ${path}/deploy.sh

12-mocknet:
	@NET=mocknet NODES=12 ${path}/deploy.sh

clean:
	helm delete mocknet -n mocknet-1
	kubectl delete ns mocknet-1
