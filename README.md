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
It is recommended to use the Makefile commands available in this repo
to start the charts with predefined configuration for most environments.

Once you have your THORNode up and running, please follow instructions [here](https://gitlab.com/thorchain/thornode) for the next steps.

## Requirements
 *  Running Kubernetes cluster
 *  Kubectl configured, ready and connected to running cluster
 *  Helm 3 (version >=3.2, can be installed using make command below)

## Running Kubernetes cluster

To get a Kubernetes cluster running, you can use the Terraform scripts [here](https://gitlab.com/thorchain/devops/terraform-scripts).

## Install Helm 3

Install Helm 3 if not already available on your current machine:

```bash
make helm
```

## Deploy tools

To deploy all tools, metrics, logs management, Kubernetes Dashboard, run the command below.

```bash
make tools
```

To destroy all those resources run the command below.

```bash
make destroy-tools
```

You can install those tools separately using the sections below.

## Deploy THORNode

It is important to deploy the tools first before deploying the THORNode services as
some services will have metrics configuration that would fail and stop the THORNode deployment.

You have multiple commands available to deploy different configurations of THORNode.
You can deploy mainnet / testnet / mocknet.
The commands deploy the umbrella chart `thornode` in the background in the Kubernetes
namespace `thornode` by default.
Unless you specify the name of your deployment using the environment variable `NAME`,
all the commands are run against the default Kubernetes namespace `thornode` set up in the Makefile.

### Deploy Mainnet Genesis

```bash
make mainnet-genesis
```

### Deploy Mainnet Validator

To automatically select the current mainnet chain, run that command:

```bash
make mainnet-validator
```

### Deploy Testnet Genesis

```bash
make testnet-genesis
```

### Deploy Testnet Validator

To automatically select the current testnet chain, run that command:

```bash
make testnet-validator
```

Or to manually specify the seed genesis IP, run that command:

```bash
SEED_TESTNET=1.2.3.4 make testnet-validator
```

## THORNode commands

The Makefile provide different commands to help you operate your THORNode.

# status

To get information about your node on how to connect to services or its IP, run the command below.
You will also get your node address and the vault address where you will need to send your bond.

```bash
make status
```

# shell

Opens a shell into your `thor-daemon` deployment:
From within that shell you have access to the `thorcli` command.

```bash
make shell
```

# logs

Display stream of logs of `thor-daemon` deployment:

```bash
make logs
```

# set-node-keys

Send a `set-node-keys` to your node, which will set your node keys automatically for you
by retrieving them directly from the `thor-daemon` deployment.

```bash
make set-node-keys
```

# set-ip-address

Send a `set-ip-address` to your node, which will set your node ip address automatically for you
by retrieving the load balancer deployed directly.

```bash
make set-ip-address
```

# set-version

Send a `set-version` to your node, which will set your node version according to the
docker image you last deployed.

```bash
make set-version
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

### Access Prometheus admin UI

We have created a make command to automate this task to access Prometheus from your
local workstation:

```bash
make prometheus
```

Open http://localhost:9090 in your browser.

### Configure alert manager within Prometheus

Full documentation can be found here https://prometheus.io/docs/alerting/latest/configuration.
You can see an example of a slack configuration and adding prometheus rules in the file `prometheus/values.yaml`.

Once you have updated the configuration, you can update your current metrics deployment
by running the install command again:

```bash
make install-metrics
```

You can access the alert-manager administration dashboard by running the command below:

```bash
make alert-manager
```

This dashboard will allow you to "silence" alerts for a specific period of time.

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
- thor-gateway: THORNode gateway proxy to get a single IP address for multiple deployments
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
- kubernetes-dashboard: Kubernetes dashboard
