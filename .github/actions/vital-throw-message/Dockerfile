FROM golang:1.25@sha256:e68f6a00e88586577fafa4d9cefad1349c2be70d21244321321c407474ff9bf2

ENV REVIEWDOG_VERSION=v0.21.0

RUN curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b $(go env GOPATH)/bin ${REVIEWDOG_VERSION}

ADD  scripts/ /scripts/

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
