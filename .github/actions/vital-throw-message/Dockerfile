FROM golang:1.25@sha256:8305f5fa8ea63c7b5bc85bd223ccc62941f852318ebfbd22f53bbd0b358c07e1

ENV REVIEWDOG_VERSION=v0.21.0

RUN curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b $(go env GOPATH)/bin ${REVIEWDOG_VERSION}

ADD  scripts/ /scripts/

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
