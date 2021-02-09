SHELL:=/bin/bash

NAME?=thornode

VERSION=chaosnet-multichain-0.17.0
VERSION_TESTNET=testnet-multichain-0.19.1

VERSION_MIDGARD=2.0.0
VERSION_MIDGARD_TESTNET=2.0.0-alpha3

BTC_BLOCKHEIGHT_START_TESTNET=1906173
BCH_BLOCKHEIGHT_START_TESTNET=1431999
LTC_BLOCKHEIGHT_START_TESTNET=1794580
ETH_BLOCKHEIGHT_START_TESTNET=9583352

BINANCE_TESTNET?=http://testnet-binance.thorchain.info:26657

SEED?=$(shell curl -s https://seed.thorchain.info/ | jq -r '. | join(",")'| sed "s/,/\\\,/g;s/|/,/g")
SEED_TESTNET?=$(shell curl -s https://testnet.seed.thorchain.info/ | jq -r '. | join(",")'| sed "s/,/\\\,/g;s/|/,/g")

MNEMONIC_CMD=kubectl run -n ${NAME} -it --rm mnemonic --image=registry.gitlab.com/thorchain/thornode --restart=Never --command -- generate | grep MASTER_MNEMONIC | cut -d '=' -f 2 | tr -d '\r'
MNEMONIC_SECRET=thornode-mnemonic
PASSWORD_CMD=read -s -p "Enter Password: " pwd; echo >&2;read -s -p "Confirm Password: " pwdconf; [ "$$pwd" = "$$pwdconf" ] && (echo >&2; echo $$pwd) || (echo >&2; echo "Passwords mismatch" >&2 && exit 1)
PASSWORD_SECRET=thornode-password
ARGS=${NAME} ./thornode-stack -n ${NAME} --create-namespace --set global.mnemonicSecret=${MNEMONIC_SECRET}
THORD_CMD=kubectl exec -it --namespace ${NAME} deploy/thornode --

help-thornode: ## Help message THORNode
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

mnemonic: ## Retrieve and display current mnemonic for backup from your THORNode
	@kubectl get -n ${NAME} secrets/${MNEMONIC_SECRET} --template={{.data.mnemonic}} | base64 --decode

password: ## Retrieve and display current password for backup from your THORNode
	@kubectl get -n ${NAME} secrets/${PASSWORD_SECRET} --template={{.data.password}} | base64 --decode

pods: ## Get THORNode Kubernetes pods
	@kubectl -n ${NAME} get pods

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
	@helm dependencies update ./thornode-stack

mocknet-genesis: create-mnemonic update-dependencies ## Install/Update a MOCKNET Genesis THORNode
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} \
		--set global.net=mocknet,global.tag=$${TAG:-mocknet},midgard.image.tag=mocknet \
		--set binance-daemon.service.type=LoadBalancer \
		--set bifrost.binanceStartBlockHeight=1

mocknet-validator: create-mnemonic update-dependencies ## Install/Update a MOCKNET Validator THORNode
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} \
		--set global.net=mocknet,global.tag=$${TAG:-mocknet},midgard.image.tag=mocknet \
		--set binance-daemon.enabled=false \
		--set global.peer=${PEER} \
		--set global.binanceDaemon=${BINANCE}

testnet-genesis: create-mnemonic update-dependencies ## Install/Update a TESTNET Genesis THORNode
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} \
		--set global.net=testnet,global.tag=$${TAG:-${VERSION_TESTNET}} \
		--set midgard.image.tag=${VERSION_MIDGARD_TESTNET} \
		--set bifrost.bitcoinStartBlockHeight=${BTC_BLOCKHEIGHT_START_TESTNET} \
		--set bifrost.ethereumStartBlockHeight=${ETH_BLOCKHEIGHT_START_TESTNET} \
		--set bifrost.litecoinStartBlockHeight=${LTC_BLOCKHEIGHT_START_TESTNET} \
		--set bifrost.bitcoinCashStartBlockHeight=${BCH_BLOCKHEIGHT_START_TESTNET}

testnet-validator: create-mnemonic update-dependencies ## Install/Update a TESTNET Validator THORNode
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} \
		--set global.net=testnet,global.tag=$${TAG:-${VERSION_TESTNET}} \
		--set midgard.image.tag=${VERSION_MIDGARD_TESTNET} \
		--set bifrost.peer='${SEED_TESTNET}',thornode.seeds='${SEED_TESTNET}'

testnet-fullnode: create-mnemonic update-dependencies ## Install/Update a TESTNET Fullnode THORNode
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} \
		--set global.net=testnet,global.tag=$${TAG:-${VERSION_TESTNET}} \
		--set midgard.image.tag=${VERSION_MIDGARD_TESTNET} \
		--set thornode.seeds='${SEED_TESTNET}' \
		--set bifrost.enabled=false,binance-daemon.enabled=false \
		--set thornode.validator=false,gateway.validator=false

testnet-update: pull testnet-validator set-version status ## Update a TESTNET Validator THORNode and set version

mainnet-genesis: create-mnemonic create-password update-dependencies ## Install/Update a MAINNET Genesis THORNode
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} \
		--set global.tag=$${TAG:-${VERSION}} \
		--set global.passwordSecret=${PASSWORD_SECRET} \
		--set midgard.image.tag=${VERSION_MIDGARD}

mainnet-validator: create-mnemonic create-password update-dependencies ## Install/Update a MAINNET Validator THORNode
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} \
		--set global.tag=$${TAG:-${VERSION}} \
		--set global.passwordSecret=${PASSWORD_SECRET} \
		--set midgard.image.tag=${VERSION_MIDGARD} \
		--set bifrost.peer='${SEED}',thornode.seeds='${SEED}'

mainnet-fullnode: create-mnemonic update-dependencies ## Install/Update a MAINNET Fullnode THORNode
	@echo Installing THORNode
	@helm upgrade --install ${ARGS} \
		--set global.tag=$${TAG:-${VERSION}} \
		--set midgard.image.tag=${VERSION_MIDGARD}
		--set thornode.seeds='${SEED}' \
		--set bifrost.enabled=false,binance-daemon.enabled=false \
		--set thornode.validator=false,gateway.validator=false

mainnet-update: pull mainnet-validator set-version status ## Update a MAINNET Validator THORNode and set version

reset-midgard: ## Reset and resync current Midgard service from scratch on your THORNode. This command can take a while to sync back to 100%.
	@kubectl exec -it -n ${NAME} sts/midgard-timescaledb -- rm -rf /var/lib/postgresql/data/pgdata
	@kubectl delete -n ${NAME} pod -l app.kubernetes.io/name=midgard

reset-binance: ## Reset and resync current Binance Node service on your THORNode. This command can take a while to sync back to 100%.
	@echo !!! Destructive command, be careful, your Binance node data will be wiped out and your Binance node will restart from scratch and sync again !!!
	@echo -n "Are you sure? Confirm [y/n] " && read ans && [ $${ans:-N} == y ]
	@kubectl scale -n ${NAME} --replicas=0 deploy/binance-daemon --timeout=5m
	@kubectl wait --for=delete pods -l app.kubernetes.io/name=binance-daemon -n ${NAME} --timeout=5m > /dev/null 2>&1 || true
	@kubectl run -n ${NAME} -it reset-binance --rm --restart=Never --image=busybox --overrides='{"apiVersion": "v1", "spec": {"containers": [{"command": ["rm", "-rf", "/bnb/config", "/bnb/data", "/bnb/.probe_last_height"], "name": "reset-binance", "stdin": true, "stdinOnce": true, "tty": true, "image": "busybox", "volumeMounts": [{"mountPath": "/bnb", "name":"data"}]}], "volumes": [{"name": "data", "persistentVolumeClaim": {"claimName": "binance-daemon"}}]}}'
	@kubectl scale -n ${NAME} --replicas=1 deploy/binance-daemon --timeout=5m

recover-binance: ## Recover current Binance Node service on your THORNode by prompting at which height the consensus failure happened
	@echo -n "From which height do you want to recover? Check the logs of your current dpeloyment and get the last height-1 at which it's crashing: " && read HEIGHT; \
		kubectl scale -n ${NAME} --replicas=0 deploy/binance-daemon --timeout=5m && \
		kubectl wait --for=delete pods -l app.kubernetes.io/name=binance-daemon -n ${NAME} --timeout=5m && \
		kubectl run -n ${NAME} -it recover-binance --rm --restart=Never --image=registry.gitlab.com/thorchain/devops/binance-node:latest --overrides='{"apiVersion": "v1", "spec": {"containers": [{"command": ["/node-binary/tools/state_recover", "'$$HEIGHT'", "/bnb"], "name": "recover-binance", "stdin": true, "stdinOnce": true, "tty": true, "image": "registry.gitlab.com/thorchain/devops/binance-node:latest", "volumeMounts": [{"mountPath": "/bnb", "name":"data"}]}], "volumes": [{"name": "data", "persistentVolumeClaim": {"claimName": "binance-daemon"}}]}}' && \
		kubectl scale -n ${NAME} --replicas=1 deploy/binance-daemon --timeout=5m

recover-thornode: ## Recover current Thor-daemon service on your THORNode and resync THORChain after a consensus failure
	@echo !!! Destructive command, only apply in case of consensus failure on thornode !!!
	@echo Be careful, your thornode data will be deleted, the service will restart and sync again
	@echo -n "Are you sure? Confirm [y/n] " && read ans && [ $${ans:-N} == y ]
	@kubectl scale -n ${NAME} --replicas=0 deploy/thornode --timeout=5m
	@kubectl wait --for=delete pods -l app.kubernetes.io/name=thornode -n ${NAME} --timeout=5m > /dev/null 2>&1 || true
	@kubectl run -n ${NAME} -it recover-thornode --rm --restart=Never --image=busybox --overrides='{"apiVersion": "v1", "spec": {"containers": [{"command": ["sh", "-c", "cd /root/.thornode/data && rm -rf bak && mkdir -p bak && mv application.db blockstore.db cs.wal evidence.db state.db tx_index.db bak/"], "name": "recover-thornode", "stdin": true, "stdinOnce": true, "tty": true, "image": "busybox", "volumeMounts": [{"mountPath": "/root", "name":"data"}]}], "volumes": [{"name": "data", "persistentVolumeClaim": {"claimName": "thornode"}}]}}'
	@kubectl scale -n ${NAME} --replicas=1 deploy/thornode --timeout=5m


wait-ready: ## Wait for all pods to be in Ready state
	@kubectl wait --for=condition=Ready --all pods -n ${NAME} --timeout=5m

destroy: status ## Uninstall current THORNode
	@echo
	@echo !!! Make sure your got your BOND back before destroying your THORNode !!!
	@echo -n "Are you sure? Confirm [y/n] " && read ans && [ $${ans:-N} == y ]
	@echo Deleting THORNode
	@helm delete ${NAME} -n ${NAME}
	@kubectl delete namespace ${NAME}

status: ## Display current status of your THORNode
	@exec ${THORD_CMD} sh -c "[ -f /scripts/node-status.sh ] && /scripts/node-status.sh || /kube-scripts/node-status.sh"

midgard: ## Access Midgard API through port-forward locally
	@echo Open your browser at http://localhost:8080
	@kubectl -n ${NAME} port-forward service/midgard 8080

shell: ## Open a shell into thornode deployment
	@exec ${THORD_CMD} sh

shell-binance: ## Open a shell into binance deployment
	@kubectl exec -it --namespace ${NAME} deploy/binance-daemon -- sh

shell-bifrost: ## Open a shell into bifrost deployment
	@kubectl exec -it --namespace ${NAME} deploy/bifrost -- sh

shell-midgard: ## Open a shell into midgard deployment
	@kubectl exec -it --namespace ${NAME} sts/midgard -- sh

shell-midgard-timescaledb: ## Open a shell into midgard-timescaledb deployment
	@kubectl exec -it --namespace ${NAME} sts/midgard-timescaledb -- sh

watch: ## Watch the thornode pods in real time
	@watch -n 1 kubectl -n ${NAME} get pods

logs: ## Display logs for thornode deployment
	@kubectl logs -f -n ${NAME} deploy/thornode

logs-binance: ## Display logs for binance-daemon deployment
	@kubectl logs -f -n ${NAME} deploy/binance-daemon

logs-bifrost: ## Display logs for bifrost deployment
	@kubectl logs -f -n ${NAME} deploy/bifrost

logs-midgard: ## Display logs for midgard deployment
	@kubectl logs -f -n ${NAME} sts/midgard

logs-midgard-timescaledb: ## Display logs for midgard-timescaledb deployment
	@kubectl logs -f -n ${NAME} sts/midgard-timescaledb

logs-telegram-bot: ## Display logs for telegram-bot deployment
	@kubectl logs -f -n ${NAME} deploy/telegram-bot

set-node-keys: ## Send a set-node-keys transaction to your THORNode
	@exec ${THORD_CMD} /kube-scripts/set-node-keys.sh > /dev/null
	@sleep 5 && echo THORNode Keys updated

set-version: ## Send a set-version transaction to your THORNode
	@exec ${THORD_CMD} /kube-scripts/set-version.sh > /dev/null
	@sleep 5 && echo THORNode version updated

set-ip-address: ## Send a set-ip-address transaction to your THORNode
	@exec ${THORD_CMD} /kube-scripts/set-ip-address.sh $(shell kubectl -n ${NAME} get configmap gateway-external-ip -o jsonpath={.data.externalIP}) > /dev/null
	@sleep 5 && echo THORNode IP address updated

telegram-bot: ## Deploy Telegram bot to monitor THORNode
	@echo "Start a Telegram chat with BotFather, click start, then send /newbot command."
	@echo -n "Enter Telegram bot token: " && read TOKEN; \
	echo -n "Select NET [testnet/chaosnet/mainnet]: " && read NET; \
	helm upgrade -n ${NAME} --install telegram-bot ./telegram-bot \
		--set telegramToken=$$TOKEN \
		--set net=$$NET

destroy-telegram-bot: ## Uninstall Telegram bot to monitor THORNode
	@helm delete telegram-bot -n ${NAME}

.PHONY: help mnemonic create-mnemonic create-password create-namespace update-dependencies pods mocknet-genesis mocknet-validator testnet-genesis testnet-validator testnet-fullnode testnet-update update mainnet-genesis mainnet-validator mainnet-fullnode mainnet-update destroy midgard status shell watch set-node-keys set-ip-address set-version telegram-bot destroy-telegram-bot recover-thornode recover-binance
