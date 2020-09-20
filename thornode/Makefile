SHELL:=/bin/bash

NAME?=thornode
VERSION_TESTNET=testnet-0.14.0
VERSION_CHAOSNET=chaosnet-0.14.0
BINANCE_TESTNET?=http://testnet-binance.thorchain.info:26657
SEED_TESTNET?=$(shell curl -s https://testnet-seed.thorchain.info/ | jq -r '. | join(",")'| sed "s/,/\\\,/g;s/|/,/g")
SEED_CHAOSNET?=$(shell curl -s https://chaosnet-seed.thorchain.info/ | jq -r '. | join(",")'| sed "s/,/\\\,/g;s/|/,/g")
SEED?=$(shell curl -s https://seed.thorchain.info/ | jq -r '. | join(",")'| sed "s/,/\\\,/g;s/|/,/g")

MNEMONIC_CMD=kubectl run -n ${NAME} -it --rm mnemonic --image=registry.gitlab.com/thorchain/thornode --restart=Never --command -- generate | grep MASTER_MNEMONIC | cut -d '=' -f 2 | tr -d '\r'
MNEMONIC_SECRET=thornode-mnemonic
PASSWORD_CMD=read -s -p "Enter Password: " pwd; echo >&2;read -s -p "Confirm Password: " pwdconf; [ "$$pwd" = "$$pwdconf" ] && (echo >&2; echo $$pwd) || (echo >&2; echo "Passwords mismatch" >&2 && exit 1)
PASSWORD_SECRET=thornode-password
ARGS=${NAME} ./thornode -n ${NAME} --create-namespace --set global.mnemonicSecret=${MNEMONIC_SECRET} --wait --timeout 10m
THORD_CMD=kubectl exec -it --namespace ${NAME} deploy/thor-daemon --
BNB_RECOVER_HEIGHT_CMD=kubectl logs -n ${NAME} deploy/binance-daemon | grep "Wrong Block.Header.AppHash" | awk -F"[()]" '{print $2}' |  cut -d ':' -f 1 | awk '{print $1-1}'

mnemonic:
	@kubectl get -n ${NAME} secrets/${MNEMONIC_SECRET} --template={{.data.mnemonic}} | base64 --decode

password:
	@kubectl get -n ${NAME} secrets/${PASSWORD_SECRET} --template={{.data.password}} | base64 --decode

create-namespace:
	@echo Creating THORNode Namespace
	@kubectl get ns ${NAME} > /dev/null 2>&1 || kubectl create ns ${NAME}

create-mnemonic: create-namespace
	@echo Generating THORNode Mnemonic phrase
	@kubectl get -n ${NAME} secrets/${MNEMONIC_SECRET} > /dev/null 2>&1 || kubectl -n ${NAME} create secret generic ${MNEMONIC_SECRET} --from-literal=mnemonic="$$(${MNEMONIC_CMD})"

create-password:
	@echo Creating THORNode Password
	@kubectl get -n ${NAME} secrets/${PASSWORD_SECRET} > /dev/null 2>&1 || (PASS="$$(${PASSWORD_CMD})" && kubectl -n ${NAME} create secret generic ${PASSWORD_SECRET} --from-literal=password="$$PASS")

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
	@helm upgrade --install ${ARGS} --set global.net=testnet,global.tag=$${TAG:-${VERSION_TESTNET}},midgard.image.tag=testnet

testnet-validator: create-mnemonic update-dependencies
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.net=testnet,global.tag=$${TAG:-${VERSION_TESTNET}},midgard.image.tag=testnet,bifrost.peer='${SEED_TESTNET}',thor-daemon.seeds='${SEED_TESTNET}'

testnet-fullnode: create-mnemonic update-dependencies
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.net=testnet,global.tag=$${TAG:-${VERSION_TESTNET}},global.gateway.enabled=true,midgard.image.tag=testnet,bifrost.enabled=false,binance-daemon.enabled=false,thor-daemon.seeds='${SEED_TESTNET}',thor-daemon.validator=false,thor-gateway.validator=false

mainnet-genesis: create-mnemonic create-password update-dependencies
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.passwordSecret=${PASSWORD_SECRET}

mainnet-validator: create-mnemonic cerate-password update-dependencies
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set bifrost.peer='${SEED}',thor-daemon.seeds='${SEED}',global.passwordSecret=${PASSWORD_SECRET}

mainnet-fullnode: create-mnemonic update-dependencies
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.gateway.enabled=true,bifrost.enabled=false,binance-daemon.enabled=false,thor-daemon.seeds='${SEED}',thor-daemon.validator=false,thor-gateway.validator=false

chaosnet-genesis: create-mnemonic create-password update-dependencies
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.tag=$${TAG:-${VERSION_CHAOSNET}},global.passwordSecret=${PASSWORD_SECRET}

chaosnet-validator: create-mnemonic create-password update-dependencies
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.tag=$${TAG:-${VERSION_CHAOSNET}},bifrost.peer='${SEED_CHAOSNET}',thor-daemon.seeds='${SEED_CHAOSNET}',global.passwordSecret=${PASSWORD_SECRET}

chaosnet-fullnode: create-mnemonic update-dependencies
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} --set global.tag=$${TAG:-${VERSION_CHAOSNET}},global.gateway.enabled=true,bifrost.enabled=false,binance-daemon.enabled=false,thor-daemon.seeds='${SEED_CHAOSNET}',thor-daemon.validator=false,thor-gateway.validator=false

reset-midgard:
	@kubectl exec -it -n ${NAME} deploy/midgard-timescaledb -- rm -rf /var/lib/postgresql/data/pgdata
	@kubectl delete -n ${NAME} pod -l app.kubernetes.io/name=midgard

reset-binance:
	@echo !!! Destructive command, be careful, your Binance node data will be wiped out and your Binance node will restart from scratch and sync again !!!
	@echo -n "Are you sure? Confirm [y/n] " && read ans && [ $${ans:-N} == y ]
	@kubectl scale -n ${NAME} --replicas=0 deploy/binance-daemon --timeout=5m
	@kubectl wait --for=delete pods -l app.kubernetes.io/name=binance-daemon -n ${NAME} --timeout=5m > /dev/null 2>&1 || true
	@kubectl run -n ${NAME} -it reset-binance --rm --restart=Never --image=busybox --overrides='{"apiVersion": "v1", "spec": {"containers": [{"command": ["rm", "-rf", "/bnb/config", "/bnb/data"], "name": "reset-binance", "stdin": true, "stdinOnce": true, "tty": true, "image": "busybox", "volumeMounts": [{"mountPath": "/bnb", "name":"data"}]}], "volumes": [{"name": "data", "persistentVolumeClaim": {"claimName": "binance-daemon"}}]}}'
	@kubectl scale -n ${NAME} --replicas=1 deploy/binance-daemon --timeout=5m

recover-binance:
	@HEIGHT="$$(${BNB_RECOVER_HEIGHT_CMD})"; [ "$$HEIGHT" == "" ] && echo Binance node height could not be parsed automatically, make sure your Binance node is currently failing from a consensus failure. || echo Binance node height parsed from logs: $$HEIGHT
	@echo -n "Check Binance node height was parsed correctly. Are you sure? Confirm [y/n] " && read ans && [ $${ans:-N} == y ]
	@kubectl scale -n ${NAME} --replicas=0 deploy/binance-daemon --timeout=5m
	@kubectl wait --for=delete pods -l app.kubernetes.io/name=binance-daemon -n ${NAME} --timeout=5m
	@kubectl run -n ${NAME} -it recover-binance --rm --restart=Never --image=registry.gitlab.com/thorchain/devops/binance-node:latest --overrides='{"apiVersion": "v1", "spec": {"containers": [{"command": ["/node-binary/tools/state_recover", "$(shell ${BNB_RECOVER_HEIGHT_CMD})", "/bnb"], "name": "recover-binance", "stdin": true, "stdinOnce": true, "tty": true, "image": "registry.gitlab.com/thorchain/devops/binance-node:latest", "volumeMounts": [{"mountPath": "/bnb", "name":"data"}]}], "volumes": [{"name": "data", "persistentVolumeClaim": {"claimName": "binance-daemon"}}]}}'
	@kubectl scale -n ${NAME} --replicas=1 deploy/binance-daemon --timeout=5m

wait-ready:
	@kubectl wait --for=condition=Ready --all pods -n ${NAME} --timeout=5m

destroy: status
	@echo
	@echo !!! Make sure your got your BOND back before destroying your THORNode !!!
	@echo -n "Are you sure? Confirm [y/n] " && read ans && [ $${ans:-N} == y ]
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

logs-bifrost:
	@kubectl logs -f -n ${NAME} deploy/bifrost

logs-midgard:
	@kubectl logs -f -n ${NAME} deploy/midgard

set-node-keys:
	@exec ${THORD_CMD} /kube-scripts/set-node-keys.sh > /dev/null
	@sleep 5 && echo THORNode Keys updated

set-version:
	@exec ${THORD_CMD} /kube-scripts/set-version.sh > /dev/null
	@sleep 5 && echo THORNode version updated

set-ip-address:
	@exec ${THORD_CMD} /kube-scripts/set-ip-address.sh $(shell kubectl -n ${NAME} get configmap thor-gateway-external-ip -o jsonpath={.data.externalIP}) > /dev/null
	@sleep 5 && echo THORNode IP address updated

.PHONY: mnemonic create-mnemonic create-password create-namespace update-dependencies mocknet-genesis mocknet-validator testnet-genesis testnet-validator testnet-fullnode chaosnet-genesis chaosnet-validator chaosnet-fullnode mainnet-genesis mainnet-validator mainnet-fullnode destroy midgard status shell set-node-keys set-ip-address
