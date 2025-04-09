FROM golang:1.24@sha256:227d106dca555769db9977f33e5d3d27422c5e75af1afc080b92f390c326de80

ENV REVIEWDOG_VERSION=v0.20.3

RUN curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b $(go env GOPATH)/bin ${REVIEWDOG_VERSION}

ADD  scripts/ /scripts/

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
