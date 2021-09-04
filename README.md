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

To deploy all tools needed, metrics, logs management, Kubernetes Dashboard, run the command below.
This will run commands: install-prometheus, install-loki, install-metrics, install-dashboard.

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

You have multiple choices available to deploy different configurations of THORNode.
You can deploy a mainnet or testnet node.
The commands deploy the umbrella chart `thornode-stack` in the background in the Kubernetes
namespace `thornode` (or `thornode-testnet` for testnet) by default.

```bash
make install
```

## THORNode commands

The Makefile provide different commands to help you operate your THORNode.

# help

To get information and description about all the commands available through this Makefile.

```bash
make help
```

# status

To get information about your node on how to connect to services or its IP, run the command below.
You will also get your node address and the vault address where you will need to send your bond.

```bash
make status
```

# shell

Opens a shell into your `thornode` deployment service selected:

```bash
make shell
```

# restart

Restart a THORNode deployment service selected:

```bash
make restart
```

# logs

Display stream of logs of a THORNode deployment selected:

```bash
make logs
```

# set-node-keys

Send a `set-node-keys` to your node, which will set your node keys automatically for you
by retrieving them directly from the `thornode` deployment.

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

# pause

Send a `pause-chain` to your node, which will globally halt THORChain. This is only to be used by node operators in the event of an emergency, such as a suspected attack on the network. This can only be done once by each node operator per churn. Nodes found absuing this command may be banned by other node operators. Use extreme caution!

```bash
make pause
```

# resume

Send a `resume-chain` to your node, which will unpause the network if it is currently paused.

```bash
make resume
```

## Destroy THORNode

To fully destroy the running node and all services, run that command:

```bash
make destroy
```

## Deploy metrics management Prometheus / Grafana stack

It is recommended to deploy a Prometheus stack to monitor your cluster
and your running services.

The metrics management is split across 2 commands: install-prometheus, install-metrics.

You can deploy the metrics management automatically using the command below:

```bash
make install-prometheus install-metrics
```

This command will deploy the prometheus chart and the metrics server files.
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

To access Grafana from a remote machine, you need to modify the grafana port-forward command to allow remote connection by adding
the option `--address 0.0.0.0` at the end of the command like this:

```bash
@kubectl -n prometheus-system port-forward service/prometheus-grafana 3000:80 --address 0.0.0.0
```

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
make install-prometheus
```

You can access the alert-manager administration dashboard by running the command below:

```bash
make alert-manager
```

This dashboard will allow you to "silence" alerts for a specific period of time.

### Destroy metrics management stack

```bash
make destroy-prometheus destroy-metrics
```

## Deploy Loki logs management stack

It is recommended to deploy a logs management ingestor stack within Kubernetes to redirect all logs
within a database to keep history over time as Kubernetes automatically rotates logs after a while
to avoid filling the disks.
The default stack used within this repository is Loki, created by Grafana and open source.
To access the logs you can then use the Grafana admin interface that was deployed through the Prometheus command.

You can deploy the log management automatically using the command below:

```bash
make install-loki
```

This command will deploy the Loki chart.
It can take a while to deploy all the services, usually up to 5 minutes
depending on resources running your kubernetes cluster.

You can check the services being deployed in your kubernetes namespace `loki-system`.

### Access Grafana

See previous section to access the Grafana admin interface through the command `make grafana`.

### Browse Logs

Within the Grafana admin interface, to access the logs, find the `Explore` view from the left menu sidebar.
Once in the `Explore` view, select Loki as the source, then select the service you want to show the logs by creating a query.
The easiest way is to open the "Log browser" menu, then select the "job" label and then as value, select the service you want.
For example you can select `thornode/bifrost` to show the logs of the Bifrost service within the default `thornode` namespace
when deploying a mainnet validator THORNode.

### Destroy Loki logs management stack

```bash
make destroy-loki
```

## Deploy Elastick Search logs management stack

If you prefer to use the Elastic Search stack, there is a command available for that.

You can deploy the ELK log management automatically using the command below:

```bash
make install-elk
```

This command will deploy the Elastic Search chart.
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

### Destroy ELK logs management stack

```bash
make destroy-elk
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

- thornode-stack: Umbrella chart packaging all services needed to run
a fullnode or validator THORNode.

This should be the only chart used to run THORNode stack unless
you know what you are doing and want to run each chart separately (not recommended).


### THORNode services:

- thornode: THORNode daemon & API
- gateway: Gateway proxy to get a single IP address for multiple deployments
- bifrost: Bifrost service
- midgard: Midgard API service

### External services:

- binance-daemon: Binance fullnode daemon
- bitcoin-daemon: Bitcoin fullnode daemon
- litecoin-daemon: Litecoin fullnode daemon
- bitcoin-cash-daemon: Bitcoin Cash fullnode daemon
- ethereum-daemon: Ethereum fullnode daemon

### Tools

- elastic-operator: ELK stack using operator for logs management
- prometheus: Prometheus stack for metrics
- loki: Loki stack for logs
- kubernetes-dashboard: Kubernetes dashboard
