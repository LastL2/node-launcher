# Multi Validator Cluster

Some node operators may desire to run multiple validators within the same cluster, while sharing a single set of daemons among them to save resource cost. This can be performed via the following method. These instructions are relevant for mainnet at the time of writing, but please ensure that correct network and current set of daemons are used.

1. Install daemons into their own namespace

```bash
NAME=daemons TYPE=daemons NET=mainnet make install
```

2. On a separate branch, add the following to the values to `lastnode-stack/mainnet.yaml`

```yaml
# point bifrost at shared daemons
bifrost:
  bitcoinDaemon:
    mainnet: bitcoin-daemon.daemons.svc.cluster.local:8332
  ethereumDaemon:
    mainnet: http://ethereum-daemon.daemons.svc.cluster.local:8545
  avaxDaemon:
    mainnet: http://avalanche-daemon.daemons.svc.cluster.local:9650/ext/bc/C/rpc

  # NOTE: This is the new format for overrides. There is plan to update the
  # config above to follow the new convention after refactoring of the Bifrost
  # config in the `lastnode` repo.
  #  env:

# disable all daemons in node namespace
bitcoin-daemon:
  enabled: false

ethereum-daemon:
  enabled: false

avalanche-daemon:
  enabled: false
```

3. Install each of the validator nodes in their own namespaces

```yaml
NAME=lastnode-1 TYPE=validator NET=mainnet make install
NAME=lastnode-2 TYPE=validator NET=mainnet make install
```

4. On each release, install both the daemons and the validators separately from the appropriate branch

```
# from master branch
NAME=daemons TYPE=daemons NET=mainnet make install

# from your branch after merging master
NAME=lastnode-1 TYPE=validator NET=mainnet make update
NAME=lastnode-2 TYPE=validator NET=mainnet make update
```
