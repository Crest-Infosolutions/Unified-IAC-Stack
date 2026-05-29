# Pipeline Runner Image

This image is the first-party runtime for:

- `jobs/infra`
- `jobs/config`
- `jobs/vault-bootstrap`

It is intended to include the minimum toolchain needed by the current job scripts:

- Azure CLI
- Terraform
- Packer
- Vault CLI
- Ansible
- kubectl
- Python 3
- `git`
- `jq`
- `openssh-client`

## Local Build

```bash
docker --context default buildx build --builder default --platform linux/amd64 -t pipeline-runner:dev images/pipeline-runner
```

## Planned Registry Path

The repo kustomizations currently point at:

```text
crest.azurecr.io/unified-iac-stack/pipeline-runner@sha256:62f9f3cdd4b83f598f2b05561c8eab7a0ef9d14c7153c0980d58e02e6a55823e
```

The image currently published for this scaffold resolves to registry digest:

```text
sha256:62f9f3cdd4b83f598f2b05561c8eab7a0ef9d14c7153c0980d58e02e6a55823e
```

Before promoting this beyond scaffold status, validate that all three job packages succeed with the pinned image and then decide whether to keep manual pinning or let CI own future tag promotion.
