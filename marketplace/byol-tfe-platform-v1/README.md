# BYOL TFE Platform v1

This directory is the Marketplace-facing package surface for the first sellable offer.

## Offer Scope

This v1 package is intentionally narrow:

- Bring your own Terraform Enterprise license
- Existing AKS cluster only
- Enterprise topology only
- LoadBalancer-only service exposure model
- External PostgreSQL, Redis, Azure Blob Storage, and Azure Key Vault
- Optional external Vault integration
- Terraform Enterprise agent included

This package does not include the bundled lab services, multi-region failover, or the optional infrastructure and configuration job packages.

## Directory Layout

```text
marketplace/byol-tfe-platform-v1/
├── chart/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
├── createUiDefinition.json
├── mainTemplate.json
└── manifest.yaml
```

## Required Customer Prerequisites

- Existing AKS cluster
- External Secrets Operator installed with support for `external-secrets.io/v1`
- Azure Key Vault populated with these secrets:
  - `tfe-secrets`
  - `tfe-agent-secrets`
  - `tfe-tls-crt`
  - `tfe-tls-key`
  - `hc-pull-secret` containing Docker auth for `crest.azurecr.io`
- Federated identity for the `azure-keyvault-reader` service account
- Federated identity for the `tfe-agent` service account
- External PostgreSQL endpoint
- External Redis endpoint
- Azure Blob Storage account and container for TFE object storage
- Optional external Vault endpoint if Vault integration is enabled

## Marketplace Notes

- `manifest.yaml` currently points at `crest.azurecr.io`. Change it only if you publish from a different ACR.
- `mainTemplate.json` contains `DONOTMODIFY` placeholders for the Marketplace plan metadata. These are expected in Marketplace samples and are completed during the packaging and Partner Center flow.
- In Partner Center Technical configuration, the cluster extension type name is a separate manual field. Set it to a unique dotted value in `PublisherName.ApplicationName` format, not an undotted offer label such as `CrestInfoUnifiedIACStack`.
- For this package, prefer `crestinfosolutions.byoltfeplatform` as the cluster extension type name so the published extension identity stays stable and recognizable.
- The cluster extension type name cannot be changed after the plan reaches Preview, so record the exact value used for each published plan.
- The chart defaults now resolve to digest-pinned Terraform Enterprise, TFE agent, and TLS init images in `crest.azurecr.io`.
- The `hc-pull-secret` Key Vault object must contain Docker auth that can pull from `crest.azurecr.io`.

## Hardened Contract Notes

- The Marketplace UI is restricted to an existing AKS cluster and a `LoadBalancer` service model.
- The chart resolves runtime images from `crest.azurecr.io` and keeps the single supported replica count for both Terraform Enterprise and the agent.
- If external Vault integration is enabled, the Vault endpoints and role must be supplied explicitly.

## Example Values

- `examples/values.enterprise.example.yaml` is a full operator-facing example.
- `examples/values.partnercenter.example.yaml` mirrors the values passed by the Marketplace UI and ARM template.

## Preview And Customer Docs

- `PARTNER-CENTER-PREVIEW-CHECKLIST.md` is the operator checklist for preview submission and dry-run validation.
- `CUSTOMER-PREREQUISITES.md` is the customer install contract for AKS, identity, Key Vault, storage, DNS, and external dependencies.
- `CUSTOMER-VALUES-MATRIX.md` maps Marketplace UI inputs, ARM parameters, Helm values, and Key Vault secret material.

## Local Validation

```bash
helm lint marketplace/byol-tfe-platform-v1/chart \
  -f marketplace/byol-tfe-platform-v1/examples/values.enterprise.example.yaml
helm template byol-tfe-platform marketplace/byol-tfe-platform-v1/chart \
  -f marketplace/byol-tfe-platform-v1/examples/values.enterprise.example.yaml
jq empty marketplace/byol-tfe-platform-v1/mainTemplate.json
jq empty marketplace/byol-tfe-platform-v1/createUiDefinition.json
```
