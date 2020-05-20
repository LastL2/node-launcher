mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
path := $(dir $(mkfile_path))

mocknet:
	@${path}/deploy.sh mocknet ${NODES} ${PEER} ${PEER_API}

testnet:
	@${path}/deploy.sh testnet ${NODES} ${PEER} ${PEER_API}

mainnet:
	@${path}/deploy.sh mainnet ${NODES} ${PEER} ${PEER_API}

clean:
	helm uninstall mocknet
