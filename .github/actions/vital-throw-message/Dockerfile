FROM golang:1.25@sha256:cc737435e2742bd6da3b7d575623968683609a3d2e0695f9d85bee84071c08e6

ENV REVIEWDOG_VERSION=v0.21.0

RUN curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b $(go env GOPATH)/bin ${REVIEWDOG_VERSION}

ADD  scripts/ /scripts/

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
