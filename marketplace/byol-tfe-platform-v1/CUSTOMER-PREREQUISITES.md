# Customer Prerequisites

This document is the customer-facing install contract for the BYOL TFE Platform v1 Marketplace offer.

## Supported v1 Topology

The supported v1 shape is intentionally narrow:

- Existing AKS cluster only
- Single region
- LoadBalancer-only service exposure
- External PostgreSQL
- External Redis
- Azure Blob Storage for Terraform Enterprise object storage
- Azure Key Vault with External Secrets Operator
- Terraform Enterprise agent included
- Optional external Vault integration

The offer does not create a new AKS cluster, does not ship bundled PostgreSQL or Redis, and does not support multi-region failover in v1.

## AKS And Namespace Requirements

| Requirement | Expectation | Notes |
| --- | --- | --- |
| Cluster type | Existing AKS managed cluster | The Marketplace package targets `Microsoft.ContainerService/managedClusters`. |
| OS and architecture | Linux AMD64 worker nodes | Microsoft Marketplace packaging for this offer targets Linux AMD64 images. |
| Extension scope | One install per cluster | `manifest.yaml` uses cluster scope. |
| Namespace | Customer-supplied namespace, default `tfeplatform` | The chart creates the namespace during install. |
| Service model | `LoadBalancer` only | Internal load balancer is optional; `ClusterIP` is not part of the v1 contract. |
| Storage | PVC-backed Terraform Enterprise data volume | Customer supplies the storage class only if the cluster default is not appropriate. |

## Required Platform Components

| Component | Requirement | Why it is needed |
| --- | --- | --- |
| External Secrets Operator | Installed before the Marketplace extension | The chart creates `ExternalSecret` resources using `external-secrets.io/v1`. |
| Azure Key Vault | Existing vault reachable from the cluster | Secret material is pulled from Key Vault at runtime. |
| Workload identity | Configured before install | The `azure-keyvault-reader` and `tfe-agent` service accounts rely on Azure workload identity. |
| DNS | Existing DNS record for the Terraform Enterprise hostname | The hostname must resolve to the service load balancer target. |
| TLS | Certificate and private key already available in Key Vault | The chart converts them into the Kubernetes TLS secret used by Terraform Enterprise. |

## Required Workload Identities

| Kubernetes service account | Required input | Purpose |
| --- | --- | --- |
| `azure-keyvault-reader` | `keyVaultClientId`, `keyVaultTenantId` | Allows External Secrets to read Key Vault objects. |
| `tfe-agent` | `armClientId`, `armTenantId`, `armSubscriptionId` | Allows the Terraform Enterprise agent to authenticate to Azure using workload identity. |

## Required Key Vault Objects

The package expects these Key Vault objects to exist before installation:

| Key Vault object | Required content | Consumed as |
| --- | --- | --- |
| `hc-pull-secret` | Docker config JSON for the image pull secret | Kubernetes secret `hc-pull-secret` with type `kubernetes.io/dockerconfigjson` |
| `tfe-secrets` | JSON object containing `TFE_LICENSE`, `TFE_ENCRYPTION_PASSWORD`, `TFE_DATABASE_PASSWORD`, `TFE_OBJECT_STORAGE_AZURE_ACCOUNT_KEY`, and `TFE_VAULT_TOKEN` | Kubernetes secret `tfe-secrets` consumed by the `tfe` deployment |
| `tfe-agent-secrets` | JSON object containing `TFC_AGENT_TOKEN` | Kubernetes secret `tfe-agent-secrets` consumed by the `tfe-agent` deployment |
| `tfe-tls-crt` | PEM-encoded certificate chain for the Terraform Enterprise hostname | Kubernetes TLS secret `tfe-tls` key `tls.crt` |
| `tfe-tls-key` | PEM-encoded private key for the Terraform Enterprise hostname | Kubernetes TLS secret `tfe-tls` key `tls.key` |

## External PostgreSQL Requirements

| Requirement | Expectation |
| --- | --- |
| Connectivity | Reachable from the AKS cluster on the supplied `host:port` |
| Database | Pre-created database for Terraform Enterprise |
| Username | Pre-created PostgreSQL user with appropriate privileges |
| Password | Stored in `tfe-secrets` as `TFE_DATABASE_PASSWORD` |
| Connection parameters | Passed as `databaseParameters`, default `sslmode=require` |

## External Redis Requirements

| Requirement | Expectation |
| --- | --- |
| Connectivity | Reachable from the AKS cluster |
| Format | A complete `redis://` or `rediss://` URL |
| Authentication | If required, embed the credential material in the Redis URL |

## Azure Blob Storage Requirements

| Requirement | Expectation |
| --- | --- |
| Storage account | Existing Azure Storage account |
| Container | Existing Blob container for Terraform Enterprise object storage |
| Account key | Stored in `tfe-secrets` as `TFE_OBJECT_STORAGE_AZURE_ACCOUNT_KEY` |
| Inputs | `objectStorageAccountName` and `objectStorageContainer` must match the real storage resources |

## DNS And TLS Requirements

| Requirement | Expectation |
| --- | --- |
| Hostname | Fully qualified hostname, for example `tfe.example.corp` |
| DNS | Hostname resolves to the provisioned load balancer endpoint |
| Certificate | TLS certificate matches the configured hostname |
| Private key | Matches the configured certificate and is stored in Key Vault |

## Optional External Vault Requirements

These items apply only when `vaultEnabled=true`.

| Requirement | Expectation |
| --- | --- |
| `vaultAddress` | Reachable HTTPS Vault API endpoint |
| `vaultClusterAddress` | Reachable HTTPS Vault cluster address |
| `vaultAuthMethod` | `kubernetes` only in v1 |
| `vaultRole` | Existing Vault role mapped for this deployment |

## Installation Day Checklist

- Confirm the AKS cluster is the intended target cluster for the preview install.
- Confirm the namespace name is approved and not already used by another instance of this offer.
- Confirm all required Key Vault objects exist with current values.
- Confirm the workload identity client IDs provided in the Marketplace UI match the intended Azure identities.
- Confirm PostgreSQL, Redis, Blob Storage, and optional Vault endpoints are reachable from the cluster network.
- Confirm DNS can be updated or already points at the expected load balancer endpoint.

## Initial Validation After Install

Run these commands in the target namespace after installation:

```bash
kubectl get externalsecret -n tfeplatform
kubectl get secret -n tfeplatform
kubectl get deploy -n tfeplatform
kubectl get svc tfe -n tfeplatform -o wide
kubectl logs deploy/tfe -n tfeplatform --tail=100
kubectl logs deploy/tfe-agent -n tfeplatform --tail=100
```

Expected first-success state:

- ExternalSecret resources show a synced or ready condition.
- Secrets `hc-pull-secret`, `tfe-secrets`, `tfe-agent-secrets`, and `tfe-tls` exist.
- Deployments `tfe` and `tfe-agent` are ready.
- The `tfe` service has a load balancer ingress target.

## Common Customer-Side Failure Modes

| Failure mode | Most likely cause |
| --- | --- |
| External secrets never materialize | Key Vault permissions or workload identity misconfiguration |
| `tfe` pod loops before readiness | Missing or incorrect values in `tfe-secrets`, database connectivity failure, or Redis connectivity failure |
| `tfe-agent` pod fails to authenticate | Invalid `TFC_AGENT_TOKEN` or Azure workload identity values |
| HTTPS endpoint fails | DNS not updated, load balancer not provisioned, or TLS material mismatch |
