#!/bin/sh

SIGNER_NAME="${SIGNER_NAME:=thorchain}"
SIGNER_PASSWD="${SIGNER_PASSWD:=password}"
MASTER_ADDR="${BTC_MASTER_ADDR:=QUt7B8gcofj7yzzvNjdXYGjkYmPX2EPkwn}"
BLOCK_TIME=${BLOCK_TIME:=1}

litecoind -regtest -txindex -rpcuser=$SIGNER_NAME -rpcpassword=$SIGNER_PASSWD -rpcallowip=0.0.0.0/0 -rpcbind=127.0.0.1 -rpcbind=$(hostname) &

# give time to litecoind to start
while true
do
	litecoin-cli -regtest -rpcuser=$SIGNER_NAME -rpcpassword=$SIGNER_PASSWD generatetoaddress 100 $MASTER_ADDR && break
	sleep 5
done

# mine a new block every BLOCK_TIME
while true
do
	litecoin-cli -regtest -rpcuser=$SIGNER_NAME -rpcpassword=$SIGNER_PASSWD generatetoaddress 1 $MASTER_ADDR
	sleep $BLOCK_TIME
done
