## --------------------------------------------------------
## Build Terraform 0.12
## --------------------------------------------------------
FROM golang:1.14.4-alpine3.12 as terraform-builder

ENV TERRAFORM_VERSION=0.12.26
ENV TF_DEV=true
ENV TF_RELEASE=true

RUN apk add --update git bash openssh

WORKDIR ${GOPATH}/src/github.com/hashicorp/terraform

RUN git clone https://github.com/hashicorp/terraform.git ./
RUN git checkout v${TERRAFORM_VERSION}
RUN /bin/bash scripts/build.sh

## --------------------------------------------------------
## Create cli container
## --------------------------------------------------------
FROM alpine:3.12

ENV HELM_VERSION=v3.2.3
ENV AWSCLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"

COPY --from=terraform-builder /go/bin/terraform /usr/local/bin

RUN apk --no-cache update && \
    apk --no-cache add ca-certificates curl groff less graphviz && \
    rm -rf /var/cache/apk/* && \
    curl -L -o awscliv2.zip ${AWSCLI_URL} && \
    unzip awscliv2.zip && \
    ./aws/install && \
    mkdir /work

WORKDIR /work
ENTRYPOINT ["terraform"]
