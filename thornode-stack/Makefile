SHELL:=/bin/bash
VERSION_MAINNET=chaosnet-multichain-0.17.0
VERSION_TESTNET=testnet-multichain-0.29.0
VERSION_MIDGARD_MAINNET=2.0.0-alpha3
VERSION_MIDGARD_TESTNET=2.0.0-alpha3

help-thornode: ## Help message THORNode
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

update-dependencies:
	@echo "=> Updating Helm chart dependencies"
	@helm dependencies update ./thornode-stack
	@echo

mnemonic: ## Retrieve and display current mnemonic for backup from your THORNode
	@./scripts/mnemonic.sh

password: ## Retrieve and display current password for backup from your THORNode
	@./scripts/password.sh

pods: ## Get THORNode Kubernetes pods
	@./scripts/pods.sh

deploy: update-dependencies ## Deploy a THORNode
	@./scripts/deploy.sh

update: pull update-dependencies ## Update a THORNode to latest version
	@./scripts/update.sh

status: ## Display current status of your THORNode
	@./scripts/status.sh

reset-midgard: ## Reset and resync current Midgard service from scratch on your THORNode. This command can take a while to sync back to 100%.
	@./scripts/reset-midgard.sh

reset-binance: ## Reset and resync current Binance Node service on your THORNode. This command can take a while to sync back to 100%.
	@./scripts/reset-binance.sh

reset-thornode: ## Reset current Thornode service on your THORNode and resync THORChain after a consensus failure
	@./scripts/reset-thornode.sh

wait-ready: ## Wait for all pods to be in Ready state
	@./scripts/wait-ready.sh

destroy: ## Uninstall current THORNode
	@./scripts/destroy.sh

shell: ## Open a shell for a selected THORNode service
	@./scripts/shell.sh

watch: ## Watch the THORNode pods in real time
	@./scripts/watch.sh

logs: ## Display logs for a selected THORNode service
	@./scripts/logs.sh

restart: ## Restart a selected THORNode service
	@./scripts/restart.sh

set-node-keys: ## Send a set-node-keys transaction to your THORNode
	@./scripts/set-node-keys.sh

set-version: ## Send a set-version transaction to your THORNode
	@./scripts/set-version.sh

set-ip-address: ## Send a set-ip-address transaction to your THORNode
	@./scripts/set-node-keys.sh

telegram-bot: ## Deploy Telegram bot to monitor THORNode
	@./scripts/telegram-bot.sh

destroy-telegram-bot: ## Uninstall Telegram bot to monitor THORNode
	@./scripts/destroy-telegram-bot.sh

.PHONY: help mnemonic update-dependencies pods deploy update destroy status shell watch logs set-node-keys set-ip-address set-version telegram-bot destroy-telegram-bot
.EXPORT_ALL_VARIABLES:
