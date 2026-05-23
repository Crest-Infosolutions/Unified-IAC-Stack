# Terraform Enterprise on AKS

This repository contains a reusable Kubernetes deployment package for running Terraform Enterprise on Azure Kubernetes Service.

The stack has been restructured around Kustomize overlays so that the same deployment can be used for both proof-of-concept environments and more durable enterprise environments. The latest pass also moves runtime secret sourcing to Azure Key Vault through External Secrets, which removes the need to create most application secrets manually inside the cluster.

## What This Repository Provides

The package is built around a shared core and three deployment profiles:

- `overlays/lab` for short-lived environments with bundled PostgreSQL, Redis, and Vault.
- `overlays/enterprise` for environments that use external platform services.
- `overlays/full-stack` for an internal full-stack AKS bundle that composes the core platform, bundled services, Vault bootstrap, and the optional automation jobs.

Across both profiles, the repository provides:

- Terraform Enterprise
- a Terraform Enterprise agent
- dedicated service accounts for each workload
- Kustomize-based environment packaging
- Azure Key Vault integration through External Secrets
- optional infrastructure and configuration jobs

## Architecture At A Glance

The deployment is organised into four layers:

- `base/` contains the shared Terraform Enterprise and agent resources.
- `bundles/bundled-services/` contains the in-cluster PostgreSQL, Redis, and Vault resources used by the lab profile.
- `integrations/azure-keyvault/` contains the Azure Key Vault `SecretStore` and `ExternalSecret` resources.
- `overlays/` assembles the final deployment for each environment profile.

Optional automation lives under `jobs/` and can be enabled after the core platform is running.

The Vault bootstrap scaffold lives under [jobs/vault-bootstrap/kustomization.yaml](/Users/radakichenin/aiprojects/Unified-IAC-Stack/jobs/vault-bootstrap/kustomization.yaml#L1), and the first-party runner image scaffold lives under [images/pipeline-runner/README.md](/Users/radakichenin/aiprojects/Unified-IAC-Stack/images/pipeline-runner/README.md#L1).

## Deployment Profiles

### Lab Profile

The lab profile is intended for demos, validation, and short-lived non-production environments. It includes:

- Terraform Enterprise
- TFE agent
- PostgreSQL in cluster
- Redis in cluster
- Vault in cluster

This is the fastest way to stand up the full stack, but it is not a production topology.

### Enterprise Profile

The enterprise profile is intended for environments where the surrounding platform services are already managed outside the cluster. It includes:

- Terraform Enterprise
- TFE agent

In this mode, the deployment expects external endpoints and credentials for services such as PostgreSQL, Redis, Vault, TLS, and object storage.

### Full-Stack Profile

The full-stack profile is an internal composition entrypoint for AKS environments where you want one overlay to render:

- Terraform Enterprise
- TFE agent
- PostgreSQL in cluster
- Redis in cluster
- Vault in cluster
- Vault bootstrap resources
- infrastructure and configuration jobs

The entrypoint is [overlays/full-stack/kustomization.yaml](/Users/radakichenin/aiprojects/Unified-IAC-Stack/overlays/full-stack/kustomization.yaml#L1). It is intended for implementation and validation work, not as a finished production topology.

## Repository Structure

```text
.
├── base/
├── bundles/
│   └── bundled-services/
├── images/
│   └── pipeline-runner/
├── integrations/
│   └── azure-keyvault/
├── jobs/
│   ├── config/
│   ├── infra/
│   └── vault-bootstrap/
└── overlays/
    ├── full-stack/
    ├── enterprise/
    └── lab/
```

If you are new to the repository, the best starting points are:

- `overlays/lab/kustomization.yaml`
- `overlays/enterprise/kustomization.yaml`
- `overlays/full-stack/kustomization.yaml`
- `base/kustomization.yaml`
- `FULL-STACK-AKS-BUNDLE-IMPLEMENTATION-PLAN.md` for the concrete file-by-file implementation plan for the full-stack AKS bundle
- `POC-CRITERIA-GAP-ANALYSIS.md` for the saved gap analysis against the stakeholder criteria captured in `criteria.docx`

## Key Improvements In This Version

This refactor focused on reuse, separation of concerns, and safer operations.

- Embedded secrets and tokens were removed from the manifests.
- Workloads no longer depend on the namespace default service account.
- Environment-specific values are separated into configuration files.
- Bundled lab services are isolated from the shared Terraform Enterprise core.
- Optional jobs are packaged separately from the main platform deployment.
- Azure Key Vault now acts as the source of truth for runtime secrets.
- Shared manifests now pin the approved runtime images to digest-based refs in `crest.azurecr.io`.

One important note remains: while the manifests no longer contain the old secret values, this repository may still contain them in Git history. Any previously committed credentials should be rotated before reuse.

## Azure Key Vault Integration

This repository now uses External Secrets Operator to pull secret material from Azure Key Vault.

In practical terms, that means:

- you no longer create the main workload secrets by hand
- the overlays create a namespace-scoped `SecretStore` for Azure Key Vault
- `ExternalSecret` resources populate the Kubernetes secret names already expected by the workloads

The package uses Azure Workload Identity with a dedicated service account named `azure-keyvault-reader` to authenticate to Key Vault.

## Before You Deploy

You should have the following in place:

- an AKS cluster
- `kubectl` with access to that cluster
- External Secrets Operator installed in the cluster with support for the `external-secrets.io/v1` API
- an Azure Key Vault containing the required secret objects
- a federated identity configured for the `azure-keyvault-reader` service account in the `tfeplatform` namespace

For enterprise environments, you should also have the external service endpoints and credentials ready before applying the overlay.

## Required Key Vault Objects

The workloads still consume Kubernetes secrets with names such as `tfe-secrets` and `tfe-tls`, but those are now generated by External Secrets from Azure Key Vault.

### Required In All Environments

Key Vault secret `tfe-secrets`

- JSON object containing `TFE_LICENSE`
- JSON object containing `TFE_ENCRYPTION_PASSWORD`
- JSON object containing `TFE_DATABASE_PASSWORD`
- JSON object containing `TFE_OBJECT_STORAGE_AZURE_ACCOUNT_KEY`
- JSON object containing `TFE_VAULT_TOKEN`

Key Vault secret `tfe-agent-secrets`

- JSON object containing `TFC_AGENT_TOKEN`

Key Vault secret `tfe-tls-crt`

- PEM certificate content for Terraform Enterprise TLS

Key Vault secret `tfe-tls-key`

- PEM private key content for Terraform Enterprise TLS

Key Vault secret `hc-pull-secret`

- Docker config JSON content used to authenticate pulls from `crest.azurecr.io` for the mirrored runtime images

### Additional Object For The Lab Profile

Key Vault secret `postgres-secrets`

- JSON object containing `POSTGRES_DB`
- JSON object containing `POSTGRES_USER`
- JSON object containing `POSTGRES_PASSWORD`

### Additional Object For The Optional Configuration Job

Key Vault secret `ssh-key`

- SSH private key content used to create `/root/.ssh/id_rsa`

### Additional Object For The Optional Automation Jobs

Key Vault secret `github-token`

- GitHub token used by Vault bootstrap to seed `secret/github` for the infra and config pipeline jobs

## Configuration Model

Environment-specific settings are managed through env files inside each overlay or job package.

For the core deployment:

- `overlays/lab/config/platform.env`
- `overlays/lab/config/keyvault.env`
- `overlays/lab/config/tfe.env`
- `overlays/lab/config/agent.env`
- `overlays/enterprise/config/platform.env`
- `overlays/enterprise/config/keyvault.env`
- `overlays/enterprise/config/tfe.env`
- `overlays/enterprise/config/agent.env`

For optional jobs:

- `jobs/config/config/platform.env`
- `jobs/config/config/job.env`
- `jobs/infra/config/platform.env`
- `jobs/infra/config/job.env`

Replace the placeholder values before deployment, especially the workload identity and Key Vault settings in `keyvault.env`.

## Security And Identity Model

The deployment now uses dedicated service accounts rather than relying on the default account in the namespace. This improves separation between workloads and gives you a cleaner path for workload identity and Vault role mapping.

Core workload identities include:

- `tfe`
- `tfe-agent`
- `postgres`
- `redis`
- `vault`
- `azure-keyvault-reader`

Optional job identities include:

- `config-pipeline`
- `infra-pipeline`

Azure workload identity annotations are sourced from the configuration files, and Vault Kubernetes authentication should be mapped to these named service accounts rather than to `default`.

## How To Deploy

Render the package first to confirm the final manifests look correct for your environment:

```bash
kubectl kustomize overlays/lab
kubectl kustomize overlays/enterprise
```

Apply the profile you want to use:

```bash
kubectl apply -k overlays/lab
kubectl apply -k overlays/enterprise
```

After applying, verify that the Key Vault integration is healthy:

```bash
kubectl get secretstore -n tfeplatform
kubectl get externalsecret -n tfeplatform
kubectl get secret -n tfeplatform
```

Optional jobs can be deployed separately after the core platform is running:

```bash
kubectl apply -k jobs/infra
kubectl apply -k jobs/config
```

The infrastructure job supports both apply and destroy behaviour through its configuration file.

## Optional Automation Jobs

Two optional job packages are included:

- `jobs/infra` for infrastructure-oriented Terraform workflows
- `jobs/config` for configuration-oriented automation after infrastructure is available

The configuration job also uses Azure Key Vault for its SSH key material.

## Recommended Starting Point

If you are evaluating the package for the first time:

1. Start with the lab profile.
2. Populate the required Key Vault objects.
3. Review the env files under the chosen overlay.
4. Render the manifests with `kubectl kustomize`.
5. Apply the overlay.
6. Confirm that the `ExternalSecret` resources have synchronized successfully.

If you are targeting a more permanent environment, start with the enterprise profile and wire it to managed platform services from the outset.

## Current Limitations

- The lab profile uses single-node bundled services and is not intended for production.
- Terraform Enterprise still consumes `TFE_VAULT_TOKEN`; it is now sourced from Azure Key Vault, but a more complete Vault bootstrap and runtime authentication flow would still be a useful next step.
- The optional job packages are pinned to the first-party runner image in `crest.azurecr.io`; validate that image against your repos and environment before production use.
