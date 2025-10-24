FROM golang:1.25@sha256:dd08f769578a5f51a22bf6a81109288e23cfe2211f051a5c29bd1c05ad3db52a

ENV REVIEWDOG_VERSION=v0.21.0

RUN curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b $(go env GOPATH)/bin ${REVIEWDOG_VERSION}

ADD  scripts/ /scripts/

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
