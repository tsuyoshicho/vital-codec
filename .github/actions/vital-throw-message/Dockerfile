FROM golang:1.24@sha256:14fd8a55e59a560704e5fc44970b301d00d344e45d6b914dda228e09f359a088

ENV REVIEWDOG_VERSION=v0.20.3

RUN curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b $(go env GOPATH)/bin ${REVIEWDOG_VERSION}

ADD  scripts/ /scripts/

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
