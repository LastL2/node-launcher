FROM alpine:3.12.1

ENV DOGECOIN_VERSION=1.14.5
ENV DOGECOIN_DATA=/home/dogecoin/.dogecoin
ENV GLIBC_VERSION=2.28-r0

WORKDIR /opt/dogecoin

RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
	&& wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk \
	&& wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk

RUN apk update \
	&& apk --no-cache add ca-certificates gnupg bash su-exec \
	&& apk --no-cache add glibc-${GLIBC_VERSION}.apk \
	&& apk --no-cache add glibc-bin-${GLIBC_VERSION}.apk

RUN wget https://github.com/dogecoin/dogecoin/releases/download/v${DOGECOIN_VERSION}/dogecoin-${DOGECOIN_VERSION}-x86_64-linux-gnu.tar.gz

RUN mkdir dogecoin \
	&& tar xzvf dogecoin-${DOGECOIN_VERSION}-x86_64-linux-gnu.tar.gz --strip-components=1 -C dogecoin \
	&& mkdir /root/.dogecoin \
	&& mv dogecoin/bin/* /usr/local/bin/ \
	&& mv dogecoin/lib/* /usr/local/lib/ \
	&& mv dogecoin/share/* /usr/local/share/ \
	&& apk del wget ca-certificates \
	&& rm -rf dogecoin* \
	&& rm -rf glibc-*

RUN adduser -S dogecoin
COPY ./scripts /scripts

EXPOSE 22555 22556 44555 44556 18332 18444
VOLUME ["/home/dogecoin/.dogecoin"]

ENTRYPOINT ["/scripts/entrypoint.sh"]
CMD ["dogecoind"]
