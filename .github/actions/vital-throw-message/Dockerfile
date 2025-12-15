FROM golang:1.25@sha256:36b4f45d2874905b9e8573b783292629bcb346d0a70d8d7150b6df545234818f

ENV REVIEWDOG_VERSION=v0.21.0

RUN curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b $(go env GOPATH)/bin ${REVIEWDOG_VERSION}

ADD  scripts/ /scripts/

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
