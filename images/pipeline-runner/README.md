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
docker build -t pipeline-runner:dev images/pipeline-runner
```

## Planned Registry Path

The repo kustomizations currently point at:

```text
crest.azurecr.io/unified-iac-stack/pipeline-runner@sha256:1d8c8397c2e54136b68af13595dd35b91a7b3a38214c23ad42db7f003bca4dce
```

The image currently published for this scaffold resolves to registry digest:

```text
sha256:1d8c8397c2e54136b68af13595dd35b91a7b3a38214c23ad42db7f003bca4dce
```

Before promoting this beyond scaffold status, validate that all three job packages succeed with the pinned image and then decide whether to keep manual pinning or let CI own future tag promotion.
