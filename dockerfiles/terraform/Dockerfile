## --------------------------------------------------------
## Build Terraform 0.12
## --------------------------------------------------------
FROM golang:1.14.4-alpine3.12 as terraform-builder
ARG terraform_version

ENV TF_DEV=true
ENV TF_RELEASE=true

RUN apk add --update git bash openssh

WORKDIR ${GOPATH}/src/github.com/hashicorp/terraform

RUN git clone https://github.com/hashicorp/terraform.git ./
RUN git checkout v${terraform_version}
RUN /bin/bash scripts/build.sh

## --------------------------------------------------------
## Create cli container
## --------------------------------------------------------
FROM alpine:3.12

COPY --from=terraform-builder /go/bin/terraform /usr/local/bin

RUN apk --no-cache update && \
    apk --no-cache add aws-cli graphviz && \
    rm -rf /var/cache/apk/* && \
    mkdir /work

WORKDIR /work
ENTRYPOINT ["terraform"]
