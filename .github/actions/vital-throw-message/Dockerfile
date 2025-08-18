FROM golang:1.25@sha256:91e2cd436f7adbfad0a0cbb7bf8502fa863ed8461414ceebe36c6304731e0fd9

ENV REVIEWDOG_VERSION=v0.20.3

RUN curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b $(go env GOPATH)/bin ${REVIEWDOG_VERSION}

ADD  scripts/ /scripts/

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
