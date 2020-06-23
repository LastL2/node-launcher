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

Charts to deploy THORNode stack and tools.
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

## Deploy THORNode

You have multiple commands available to deploy different configurations of THORNode.
You can deploy mainnet / testnet / mocknet.
The commands deploy the umbrella chart `thornode` in the background in the kubernetes
namespace `thornode` by default.

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
export PEER=$(kubectl get pods --namespace thornode -l "app.kubernetes.io/name=thor-daemon,app.kubernetes.io/instance=thornode" -o jsonpath="{.items[0].status.podIP}")
echo $PEER
```
Then in the same terminal where you previously exported the PEER env variable, you can run:

```bash
make testnet-validator
```

Or to manually specify the PEER IP, run that command:

```bash
PEER=1.2.3.4 make testnet-validator
```

Slim version validator:

```bash
PEER=1.2.3.4 make testnet-slim-validator
```

## Destroy THORNode

To fully destroy the running node and all services, run that command:

```bash
make destroy
```

## Deploy logs management Elastic Search stack

It is recommended to deploy an Elastic Search / Logstash / Filebeat / Kibana to redirect all logs
within an elasticsearch database and available through the UI Kibana.

You can deploy the log management automatically using the command below:

```bash
make install-logs
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

Login as the `elastic` user. The password can be obtained with the following command:

```bash
kubectl -n elastic-system get secret elasticsearch-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode; echo
```

### Destroy logs management stack

```bash
make destroy-logs
```


## Deploy metrics management Prometheus stack

It is also recommended to deploy a Prometheus stack to monitor your cluster
and your running services.

You can deploy the metrics management automatically using the command below:

```bash
make install-metrics
```

This command will deploy the prometheus chart.
It can take a while to deploy all the services, usually up to 5 minutes
depending on resources running your kubernetes cluster.

You can check the services being deployed in your kubernetes namespace `prometheus-system`.

### Access Grafana

We have created a make command to automate this task to access Grafana from your
local workstation:

```bash
make grafana
```

Open http://localhost:3000 in your browser.

Login as the `admin` user. The default password should have been displayed in the previous command (`make grafana`).

### Destroy metrics management stack

```bash
make destroy-metrics
```

## Deploy Kubernetes Dashboard

You can also deploy the Kubernetes dashboard to monitor your cluster resources.

```bash
make install-dashboard
```

This command will deploy the Kubernetes dashboard chart.
It can take a while to deploy all the services, usually up to 5 minutes
depending on resources running your kubernetes cluster.


### Access Dashboard

We have created a make command to automate this task to access the Dashboard from your
local workstation:

```bash
make dashboard
```

Open http://localhost:8000 in your browser.


### Destroy Kubernetes dashboard

```bash
make destroy-dashboard
```


## Charts available:

### THORNode full stack umbrella chart

- thornode: Umbrella chart packaging all services needed to run
a fullnode or validator THORNode.

This should be the only chart used to run THORNode stack unless
you know what you are doing and want to run each chart separately (not recommended).


### THORNode services:

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
