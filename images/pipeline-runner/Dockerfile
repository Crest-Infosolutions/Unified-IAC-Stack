FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG TERRAFORM_VERSION=1.9.8
ARG PACKER_VERSION=1.11.2
ARG VAULT_VERSION=1.17.5
ARG ANSIBLE_CORE_VERSION=2.17.9
ARG KUBECTL_VERSION=v1.36.1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        jq \
        lsb-release \
        openssh-client \
        python3 \
        python3-pip \
        software-properties-common \
        unzip \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://aka.ms/InstallAzureCLIDeb | bash

RUN python3 -m pip install --no-cache-dir "ansible-core==${ANSIBLE_CORE_VERSION}"

RUN curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && chmod +x /usr/local/bin/kubectl

RUN curl -fsSLo /tmp/terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
    && unzip -o /tmp/terraform.zip -d /usr/local/bin \
    && rm /tmp/terraform.zip

RUN curl -fsSLo /tmp/packer.zip "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip" \
    && unzip -o /tmp/packer.zip -d /usr/local/bin \
    && rm /tmp/packer.zip

RUN curl -fsSLo /tmp/vault.zip "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip" \
    && unzip -o /tmp/vault.zip -d /usr/local/bin \
    && rm /tmp/vault.zip

RUN terraform version \
    && packer version \
    && vault version \
    && ansible --version \
    && kubectl version --client \
    && az version >/tmp/az-version.json \
    && python3 --version \
    && jq --version

WORKDIR /workspace

ENTRYPOINT ["/bin/bash"]