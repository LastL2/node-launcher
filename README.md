Helm Charts

****

> **Mirror**
>
> This repo mirrors from THORChain Gitlab to Github.
> To contribute, please contact the team and commit to the Gitlab repo:
>
> https://gitlab.com/thorchain/devops/helm-charts


****
========

Charts to deploy THORChain stack and tools.
It is recommended to use the make commands available in this repo
to start the charts with predefined configuration for most environments.

## Requirements
 *  Running Kubernetes cluster
 *  Kubectl configured, ready and connected to running cluster
 *  Helm 3 (version >=3.2, can be installed using make command below)


## Install Helm 3

Install Helm 3 if not already available on your current machine:

```bash
make helm
```

## Deploy THORChain

You have multiple commands available to deploy different configurations of THORChain.
You can deploy mainnet / testnet / mocknet.
The commands deploy the umbrella chart `thorchain` in the background in the kubernetes
namespace `thorchain` by default.

### Deploy Mainnet Genesis

```bash
make mainnet
```

### Deploy Mainnet Validator

```bash
make mainnet-validator
```

### Deploy Testnet Genesis

If you want to run your own Binance Node included in your stack, run:

```bash
make testnet
```

Or to connect to Binance Testnet available at http://testnet-binance.thorchain.info:26657, run:

```bash
make testnet-slim
```

### Deploy Testnet Validator

To retrieve the PEER IP of your genesis node run that command on the cluster running
the genesis node:

```bash
export PEER=$(kubectl get pods --namespace thorchain -l "app.kubernetes.io/name=thor-daemon,app.kubernetes.io/instance=thorchain" -o jsonpath="{.items[0].status.podIP}")
echo $PEER
```
Then in the same terminal where you exporeted the PEER env variable, you can run:

```bash
make testnet-validator
```

Or to manually specify the PEER IP, run that command:

```bash
PEER=1.2.3.4 make testnet-validator
```

Slim version:

```bash
PEER=1.2.3.4 make testnet-slim-validator
```

## Deploy logs management Elastic Search stack

It is recommended to deploy an Elastic Search / Logstash / Filebeat / Kibana to redirect all logs
within an elasticsearch database and available through the UI Kibana.

You can deploy the log management automatically using the command below:

```bash
make logs
```

This command will deploy the elastic-operator chart.
It can take a while to deploy all the services, usually up to 5 minutes
depending on resources running your kubernetes cluster.

You can check the services being deployed in your kubernetes namespace `elastic-system`.

### Access Kibana

We have created a make command to automate this task to access Kibana from your
local workstation:

```bash
make kibana
```

Open https://localhost:5601 in your browser. Your browser will show a warning because the self-signed
certificate configured by default is not verified by a third party certificate authority
and not trusted by your browser. You can temporarily acknowledge the warning for the purposes
of this quick start but it is highly recommended that you configure valid certificates for any production deployments.

Login as the elastic user. The password should have been displayed in the previous command (`make kibana`).


To manually access Kibana follow these instructions:
A ClusterIP Service is automatically created for Kibana:

```bash
kubectl -n elastic-system get service elasticsearch-kb-http
```

Use kubectl port-forward to access Kibana from your local workstation:

```bash
kubectl -n elastic-system port-forward service/elasticsearch-kb-http 5601
```

Login as the elastic user. The password can be obtained with the following command:

```bash
kubectl -n elastic-system get secret elasticsearch-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode; echo
```

### Remove logs management stack

```bash
make clean-logs
```


## Deploy metrics management Prometheus stack

It is also recommended to deploy a Prometheus stack to monitor your cluster
and your running services.

You can deploy the metrics management automatically using the command below:

```bash
make metrics
```

This command will deploy the prometheus chart.
It can take a while to deploy all the services, usually up to 5 minutes
depending on resources running your kubernetes cluster.

You can check the services being deployed in your kubernetes namespace `metrics`.

### Access Grafana

We have created a make command to automate this task to access Grafana from your
local workstation:

```bash
make grafana
```

Open http://localhost:5601 in your browser.

Login as the admin user. The default password should have been displayed in the previous command (`make grafana`).

### Remove metrics management stack

```bash
make clean-metrics
```


## Charts available:

### THORChain full stack umbrella chart

- thorchain: Umbrella chart packaging all services needed to run
a fullnode or validator THORChain node.

This should be the only chart used to run THORChain stack unless
you know what you are doing and want to run each chart separately (not recommended).


### THORChain services:

- thor-daemon: THORNode daemon
- thor-api: THORNode API
- bepswap: BEPSwap UI frontend
- bifrost: Bifrost service
- midgard: Midgard service

### External services:

- binance-daemon: Binance fullnode daemon
- bitcoin-daemon: Bitcoin fullnode daemon
- ethereum-daemon: Ethereum fullnode daemon

### Tools

- elastic: ELK stack, deperecated. Use elastic-operator chart
- elastic-operator: ELK stack using operator for logs management
- prometheus: Prometheus stack for metrics
