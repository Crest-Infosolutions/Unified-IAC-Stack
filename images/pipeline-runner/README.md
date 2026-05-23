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
- Python 3
- `git`
- `jq`
- `openssh-client`

## Local Build

```bash
docker build -t pipeline-runner:dev images/pipeline-runner
```

## Planned Registry Path

The repo kustomizations currently point at:

```text
crest.azurecr.io/unified-iac-stack/pipeline-runner:sha-109e1fd90991
```

The image currently published for this scaffold resolves to registry digest:

```text
sha256:f6cd93427197401785c2ef594292a11b4181b90f8a54b309fae0dd1485e231cb
```

Before promoting this beyond scaffold status, validate that all three job packages succeed with the pinned image and then decide whether to keep manual pinning or let CI own future tag promotion.
