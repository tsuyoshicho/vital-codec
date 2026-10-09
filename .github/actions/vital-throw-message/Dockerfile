FROM golang:1.27@sha256:e432b43af23a9328d56a7c499be0476810aa344acbcf65fc7c455d4ff5a40602

ENV REVIEWDOG_VERSION=v0.21.2

RUN curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b $(go env GOPATH)/bin ${REVIEWDOG_VERSION}

ADD  scripts/ /scripts/

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
