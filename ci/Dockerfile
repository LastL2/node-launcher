FROM mvdan/shfmt:v3.3.0-alpine AS shfmt

FROM debian:11-slim

# Build the Docker image used for running this repository's CI.

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    shellcheck curl gpg

COPY --from=shfmt /bin/shfmt /usr/local/bin/

COPY scripts /tmp/scripts
RUN cd /tmp && \
    ./scripts/install-helm.sh && \
    rm -rf /tmp/scripts

WORKDIR /repo
