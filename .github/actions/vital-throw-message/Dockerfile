FROM golang:1.24@sha256:db5d0afbfb4ab648af2393b92e87eaae9ad5e01132803d80caef91b5752d289c

ENV REVIEWDOG_VERSION=v0.20.3

RUN curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b $(go env GOPATH)/bin ${REVIEWDOG_VERSION}

ADD  scripts/ /scripts/

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
