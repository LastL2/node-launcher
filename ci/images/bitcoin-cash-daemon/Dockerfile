FROM debian:11-slim as installer

ENV BITCOIN_VERSION=26.0.0
ENV BITCOIN_URL=https://github.com/bitcoin-cash-node/bitcoin-cash-node/releases/download/v$BITCOIN_VERSION/bitcoin-cash-node-$BITCOIN_VERSION-x86_64-linux-gnu.tar.gz
ENV BITCOIN_SHA256=e32e05fd63161f6f1fe717fca789448d2ee48e2017d3d4c6686b4222fe69497e

WORKDIR /work

RUN apt-get update \
  && apt-get -y install --no-install-recommends wget ca-certificates gnupg

RUN set -ex \
	&& wget -qO bitcoin.tar.gz "$BITCOIN_URL" \
	&& echo "$BITCOIN_SHA256  bitcoin.tar.gz" | sha256sum -c - \
  && mkdir -p /work/bitcoin \
	&& tar -xzvf bitcoin.tar.gz -C /work/bitcoin --strip-components=1 --exclude=*-qt

FROM debian:11-slim

COPY --from=installer /work/bitcoin/bin/* /usr/local/bin/
COPY --from=installer /work/bitcoin/lib/* /usr/local/lib/
COPY --from=installer /work/bitcoin/share/* /usr/local/share/

COPY ./scripts /scripts

RUN useradd --create-home bitcoin
USER bitcoin

EXPOSE 8332 8333 18332 18333 18443 18444
VOLUME ["/home/bitcoin/.bitcoin"]

ENTRYPOINT ["/scripts/entrypoint.sh"]
CMD ["bitcoind"]
