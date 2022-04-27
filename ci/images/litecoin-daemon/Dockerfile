FROM alpine:3.12.1

ENV LITECOIN_VERSION=0.18.1
ENV GLIBC_VERSION=2.28-r0
ENV LITECOIN_DATA=/home/litecoin/.litecoin

WORKDIR /opt/litecoin

RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
	&& wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk \
	&& wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk

RUN apk update \
	&& apk --no-cache add ca-certificates gnupg bash su-exec \
	&& apk --no-cache add glibc-${GLIBC_VERSION}.apk \
	&& apk --no-cache add glibc-bin-${GLIBC_VERSION}.apk

RUN for key in \
	B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	FE3348877809386C \
	; do \
		gpg --no-tty --keyserver pgp.mit.edu --recv-keys "$key" || \
		gpg --no-tty --keyserver keyserver.pgp.com --recv-keys "$key" || \
		gpg --no-tty --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" || \
		gpg --no-tty --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" ; \
	done

RUN wget https://download.litecoin.org/litecoin-${LITECOIN_VERSION}/linux/litecoin-${LITECOIN_VERSION}-x86_64-linux-gnu.tar.gz \
	&& wget https://download.litecoin.org/litecoin-${LITECOIN_VERSION}/linux/litecoin-${LITECOIN_VERSION}-linux-signatures.asc \
	&& gpg --verify litecoin-${LITECOIN_VERSION}-linux-signatures.asc \
	&& tar --strip=2 -xzf *.tar.gz -C /usr/local/bin \
	&& rm *.tar.gz

RUN adduser -S litecoin
COPY ./scripts /scripts

EXPOSE 9332 9333 19332 19333 19443 19444
VOLUME ["/home/litecoin/.litecoin"]

ENTRYPOINT ["/scripts/entrypoint.sh"]
CMD ["litecoind"]
