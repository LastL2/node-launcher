mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
path := $(dir $(mkfile_path))

mocknet:
	@NET=mocknet ${path}/deploy.sh

3-mocknet:
	@NET=mocknet NODES=3 ${path}/deploy.sh

12-mocknet:
	@NET=mocknet NODES=12 ${path}/deploy.sh

testnet:
	@NET=testnet ${path}/deploy.sh

mainnet:
	@NET=mainnet ${path}/deploy.sh

clean:
	helm uninstall mocknet
