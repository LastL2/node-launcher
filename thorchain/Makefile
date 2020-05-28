mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
path := $(dir $(mkfile_path))

mocknet:
	@NET=mocknet ${path}/deploy.sh

validator:
	@NET=mocknet TAG=mocknet ${path}/deploy.sh

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
	kubectl delete ns mocknet-1
