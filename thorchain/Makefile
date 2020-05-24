mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
path := $(dir $(mkfile_path))

mocknet:
	@NET=mocknet ${path}/deploy.sh

validator:
	@NET=mocknet TAG=mocknet PEER=157.245.190.189 PEER_API=157.245.190.189 PEER_BINANCE=167.99.24.112 PEER_BIFROST=157.245.190.189 ${path}/deploy.sh

3-mocknet:
	@NET=mocknet NODES=4 TAG=mocknet ${path}/deploy.sh

12-mocknet:
	@NET=mocknet NODES=12 ${path}/deploy.sh

testnet:
	@NET=testnet ${path}/deploy.sh

mainnet:
	@NET=mainnet ${path}/deploy.sh

clean:
	helm delete mocknet -n mocknet-1
	helm delete mocknet -n mocknet-2
	helm delete mocknet -n mocknet-3
	helm delete mocknet -n mocknet-4
	kubectl delete ns mocknet-1 mocknet-2 mocknet-3 mocknet-4
