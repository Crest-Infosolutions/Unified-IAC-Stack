# Full-Stack AKS Bundle Implementation Plan

## Goal

Build an internal AKS bundle that can deploy all of the following from one entrypoint:

- Terraform Enterprise
- Terraform Enterprise agent
- Bundled HashiCorp Vault in AKS
- Infrastructure pipeline job with Terraform and optional Packer
- Configuration pipeline job with Ansible

This plan does **not** expand the current Marketplace v1 offer. The Marketplace package should remain narrow and enterprise-only while the full-stack bundle is implemented as an internal AKS deployment surface.

## Target Outcome

At the end of this work, the repo should have a new `overlays/full-stack` entrypoint that renders and applies:

- shared TFE core from `base/`
- bundled PostgreSQL, Redis, and Vault from `bundles/bundled-services/`
- Azure Key Vault integration from `integrations/azure-keyvault/`
- the infra pipeline job
- the config pipeline job
- a Vault bootstrap job that makes the bundled Vault usable
- pinned, ACR-hosted images for TFE, TFE agent, Vault, BusyBox, and the pipeline runner image

## Design Decisions

1. Keep `marketplace/byol-tfe-platform-v1/` unchanged in scope.
2. Implement the new full-stack deployment as a new overlay at `overlays/full-stack/`.
3. Reuse the existing raw job manifests from `jobs/infra/` and `jobs/config/` instead of including those kustomizations directly.
4. Add a dedicated Vault bootstrap package because the current bundled Vault manifest only starts the server; it does not initialize, unseal, or configure Kubernetes auth.
5. Build one first-party runner image for Terraform, Vault CLI, Packer, Ansible, Azure CLI, `jq`, `git`, and `python3`.
6. Mirror all runtime images into `crest.azurecr.io` and pin tags or digests.

## Why A New Overlay Instead Of Reusing The Current Job Kustomizations

Do not compose `jobs/infra/kustomization.yaml` and `jobs/config/kustomization.yaml` directly into the new overlay.

Reason:

- the core overlays already generate `platform-config`
- `jobs/infra/kustomization.yaml` also generates `platform-config`
- `jobs/config/kustomization.yaml` also generates `platform-config`

That will create ConfigMap name collisions in a combined kustomization. The full-stack overlay should instead include the raw resource files from `jobs/infra/` and `jobs/config/` and generate all needed ConfigMaps itself.

## Phase 1: Functional Full-Stack Bundle

### Files To Add

| File | Purpose |
| --- | --- |
| `overlays/full-stack/kustomization.yaml` | New top-level full-stack entrypoint that composes base, bundled services, Key Vault integration, raw job manifests, and Vault bootstrap resources. |
| `overlays/full-stack/namespace.yaml` | Namespace manifest for the full-stack overlay. |
| `overlays/full-stack/config/platform.env` | Shared platform settings for ARM OIDC, Vault address, and service-level defaults. |
| `overlays/full-stack/config/keyvault.env` | Azure Key Vault reader identity and vault URL settings. |
| `overlays/full-stack/config/tfe.env` | TFE application configuration for the full-stack bundle. |
| `overlays/full-stack/config/agent.env` | TFE agent configuration. |
| `overlays/full-stack/config/infra-job.env` | Full-stack-specific config for the infra pipeline job. |
| `overlays/full-stack/config/config-job.env` | Full-stack-specific config for the config pipeline job. |
| `overlays/full-stack/config/vault-bootstrap.env` | Inputs for Vault initialization, unseal storage, auth method, roles, and policies. |
| `jobs/vault-bootstrap/kustomization.yaml` | Reusable package for Vault bootstrap resources. |
| `jobs/vault-bootstrap/serviceaccount.yaml` | Service account for the Vault bootstrap job. |
| `jobs/vault-bootstrap/rbac.yaml` | Permissions for the bootstrap job to create/update Kubernetes secrets if keys/tokens are stored in-cluster during the POC phase. |
| `jobs/vault-bootstrap/job.yaml` | Job that initializes Vault, unseals it, enables Kubernetes auth, writes policies, and creates the required roles. |
| `jobs/vault-bootstrap/config/job.env` | Default env values for Vault bootstrap behavior. |
| `jobs/vault-bootstrap/policies/tfe.hcl` | Vault policy for Terraform Enterprise access. |
| `jobs/vault-bootstrap/policies/tfe-agent.hcl` | Vault policy for the TFE agent role. |
| `jobs/vault-bootstrap/policies/infra-pipeline.hcl` | Vault policy for the infra job. |
| `jobs/vault-bootstrap/policies/config-pipeline.hcl` | Vault policy for the config job. |
| `images/pipeline-runner/Dockerfile` | First-party image containing Terraform, Vault CLI, Azure CLI, Packer, Ansible, Python, `jq`, and `git`. |
| `images/pipeline-runner/README.md` | Build and versioning instructions for the runner image. |
| `.github/workflows/pipeline-runner.yml` | CI workflow to build and push the runner image to `crest.azurecr.io`. |

### Image Files To Change

| File | Change |
| --- | --- |
| `README.md` | Add a new section for `overlays/full-stack`, document the full-stack deployment flow, and distinguish it from both `overlays/lab` and the Marketplace package. |
| `bundles/bundled-services/vault.yaml` | Parameterize addresses, add readiness/startup probes, and prepare the manifest for bootstrap and future TLS hardening. |
| `base/tfe.yaml` | Repoint the TFE image to `crest.azurecr.io`, pin the tag or digest, and align the pull secret contract with the mirrored image source. |
| `base/tfe-agent.yaml` | Repoint the TFE agent image to `crest.azurecr.io`, remove `latest`, and pin a concrete tag or digest. |
| `jobs/infra/job.yaml` | Add configurable Git refs, make the runner assumptions explicit, and prepare the script for a non-placeholder runner image. |
| `jobs/config/job.yaml` | Add configurable Git refs, make the runner assumptions explicit, and prepare the script for a non-placeholder runner image. |
| `jobs/infra/kustomization.yaml` | Replace `ghcr.io/example/pipeline:latest` with the real `crest.azurecr.io` runner image and tag. |
| `jobs/config/kustomization.yaml` | Replace `ghcr.io/example/pipeline:latest` with the real `crest.azurecr.io` runner image and tag. |
| `jobs/infra/config/job.env` | Replace placeholder repos and image registry settings with Crest-owned repos and supported defaults. |
| `jobs/config/config/job.env` | Replace placeholder repos with Crest-owned repos and supported defaults. |

### What `overlays/full-stack/kustomization.yaml` Should Include

The new full-stack overlay should include these resources directly:

- `namespace.yaml`
- `../../base`
- `../../bundles/bundled-services`
- `../../integrations/azure-keyvault/lab`
- `../../integrations/azure-keyvault/jobs-config`
- `../../jobs/infra/serviceaccount.yaml`
- `../../jobs/infra/job.yaml`
- `../../jobs/config/serviceaccount.yaml`
- `../../jobs/config/job.yaml`
- `../../jobs/vault-bootstrap`

It should generate these ConfigMaps:

- `platform-config`
- `keyvault-config`
- `tfe-config`
- `tfe-agent-config`
- `infra-pipeline-config`
- `config-pipeline-config`
- `vault-bootstrap-config`

It should apply replacements for these service accounts:

- `tfe-agent`
- `azure-keyvault-reader`
- `infra-pipeline`
- `config-pipeline`

It should override these images:

- `images.releases.hashicorp.com/hashicorp/terraform-enterprise:v202501-1`
- `hashicorp/tfc-agent:latest`
- `hashicorp/vault:1.17.3`
- `busybox`
- `pipeline-image`

## Phase 2: Make The Bundle Actually Usable End-To-End

### Vault Gaps To Close

The current bundled Vault only starts a single pod. It does not:

- initialize Vault
- unseal Vault
- enable Kubernetes auth
- write policies
- create roles for `tfe`, `tfe-agent`, `infra-pipeline`, and `config-pipeline`
- seed the GitHub token path consumed by the pipeline jobs

### Files To Add Or Change For Vault Usability

| File | Action |
| --- | --- |
| `jobs/vault-bootstrap/job.yaml` | Implement idempotent bootstrap logic: `vault status`, `vault operator init`, unseal, `auth enable kubernetes`, `auth/kubernetes/config`, policy writes, and role creation. |
| `jobs/vault-bootstrap/policies/*.hcl` | Store the Vault policies as versioned files in repo instead of embedding them inline in the job. |
| `bundles/bundled-services/vault.yaml` | Add health probes and optional TLS mounts so the bootstrap job can wait on a predictable readiness condition. |
| `README.md` | Document bootstrap order: deploy full-stack overlay, wait for Vault, run bootstrap, verify roles, then run infra/config jobs. |

### Minimal POC Compromise

For the first working version, keep `TFE_VAULT_TOKEN` in `tfe-secrets` so Terraform Enterprise can start without redesigning its runtime Vault auth flow immediately.

### Planned Follow-Up Hardening

After the first working bundle, redesign TFE’s Vault integration so the platform stops depending on a static `TFE_VAULT_TOKEN` sourced from Azure Key Vault.

Files to change in that follow-up:

- `integrations/azure-keyvault/common/tfe-secrets.yaml`
- `README.md`
- `marketplace/byol-tfe-platform-v1/CUSTOMER-PREREQUISITES.md`
- `marketplace/byol-tfe-platform-v1/CUSTOMER-VALUES-MATRIX.md`

## Phase 3: Productize The Pipeline Jobs

### Current Gaps

- both jobs still use `pipeline-image`
- no Dockerfile exists in repo for that image
- the jobs clone personal repos instead of first-party repos
- the infra job still does `terraform apply -auto-approve`

### Files To Add Or Change

| File | Action |
| --- | --- |
| `images/pipeline-runner/Dockerfile` | Build the real runner image. |
| `.github/workflows/pipeline-runner.yml` | Build/push the image to `crest.azurecr.io`. |
| `jobs/infra/kustomization.yaml` | Point to `crest.azurecr.io/<repo>/pipeline-runner:<tag>`. |
| `jobs/config/kustomization.yaml` | Point to `crest.azurecr.io/<repo>/pipeline-runner:<tag>`. |
| `jobs/infra/config/job.env` | Replace `santosh0123456/lz-modules`, `santosh0123456/packer-images`, and `santosh0123456/image-registry` with Crest-owned repos. |
| `jobs/config/config/job.env` | Replace `santosh0123456/lz-modules` and `santosh0123456/ansible` with Crest-owned repos. |
| `jobs/infra/job.yaml` | Add `LZ_MODULES_REF`, `PACKER_REF`, and `IMAGE_REGISTRY_REF`; split `plan` and `apply` cases; stop forcing `auto-approve` in the long-term design. |
| `jobs/config/job.yaml` | Add `LZ_MODULES_REF` and `ANSIBLE_REF`; make SSH wait/retry behavior explicit and configurable. |

### Runner Image Contents

The runner image should include:

- `terraform`
- `vault`
- `az`
- `packer`
- `ansible`
- `python3`
- `jq`
- `git`
- `openssh-client`

## Phase 4: Image Governance And ACR Mirroring

### Runtime Images That Should Be Mirrored To `crest.azurecr.io`

- Terraform Enterprise
- TFE agent
- Vault
- BusyBox
- pipeline runner image

### Files To Change

| File | Action |
| --- | --- |
| `base/tfe.yaml` | Use mirrored TFE image. |
| `base/tfe-agent.yaml` | Use mirrored TFE agent image. |
| `bundles/bundled-services/vault.yaml` | Use mirrored Vault image. |
| `base/tfe.yaml` | Use mirrored BusyBox init image. |
| `overlays/full-stack/kustomization.yaml` | Declare the exact image overrides used by the full-stack bundle. |
| `README.md` | Document the image mirroring contract and required pull secret behavior. |

## Suggested Implementation Order

1. Add the pipeline runner image build path.
2. Mirror and pin TFE, TFE agent, Vault, and BusyBox into `crest.azurecr.io`.
3. Add `jobs/vault-bootstrap/`.
4. Add `overlays/full-stack/` and compose base + bundled services + Key Vault + jobs.
5. Replace placeholder repos in the job env files.
6. Validate `kubectl kustomize overlays/full-stack`.
7. Deploy to a dev AKS cluster.
8. Verify Vault bootstrap.
9. Run `jobs/infra` with `RUN_PACKER=false` first.
10. Run `jobs/config` after infra outputs exist.
11. Turn on `RUN_PACKER=true` after the runner image and Packer repo path are verified.

## Validation Gates

### Static Validation

- `kubectl kustomize overlays/full-stack`
- `kubectl apply --dry-run=server -k overlays/full-stack`

### Runtime Validation

- TFE pod healthy
- TFE agent pod healthy
- Vault pod healthy
- Vault initialized and unsealed
- `vault auth list` includes Kubernetes auth
- `vault read auth/kubernetes/role/infra-pipeline`
- `vault read auth/kubernetes/role/config-pipeline`
- infra job completes with `terraform init` and `terraform plan`
- config job completes with `ansible-playbook`

## Explicit Non-Goals For This Work

- Do not broaden `marketplace/byol-tfe-platform-v1` to include bundled services or optional job packages in this phase.
- Do not redesign the Partner Center package while building the internal full-stack overlay.
- Do not treat the current single-node bundled Vault as production-ready until the TLS, HA, and bootstrap work is complete.

## Recommended First PR Slice

The first implementation PR should be deliberately narrow and should contain only:

- `images/pipeline-runner/Dockerfile`
- `.github/workflows/pipeline-runner.yml`
- `jobs/vault-bootstrap/`
- `overlays/full-stack/`
- `README.md`

That slice is the smallest change set that creates a real full-stack entrypoint without forcing Marketplace changes.
