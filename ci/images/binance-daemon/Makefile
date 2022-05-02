docker-gitlab-login:
	docker login -u ${CI_REGISTRY_USER} -p ${CI_REGISTRY_PASSWORD} ${CI_REGISTRY}

docker-gitlab-build:
	docker build -t registry.gitlab.com/thorchain/devops/binance-node .

docker-gitlab-push:
	docker push registry.gitlab.com/thorchain/devops/binance-node:latest
