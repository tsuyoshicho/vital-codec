FROM golang:1.24@sha256:2c89c41fb9efc3807029b59af69645867cfe978d2b877d475be0d72f6c6ce6f6

ENV REVIEWDOG_VERSION=v0.20.3

RUN curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b $(go env GOPATH)/bin ${REVIEWDOG_VERSION}

ADD  scripts/ /scripts/

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
