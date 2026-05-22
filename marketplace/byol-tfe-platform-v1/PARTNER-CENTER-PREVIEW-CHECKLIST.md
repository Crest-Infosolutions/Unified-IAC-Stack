# Partner Center Preview Checklist

Use this checklist before opening a limited preview for the BYOL TFE Platform v1 offer.

## Offer Record

- [ ] Offer type is Azure Kubernetes Application targeting AKS managed clusters only.
- [ ] The offer description matches the actual v1 scope: BYOL Terraform Enterprise, existing AKS only, external PostgreSQL, external Redis, Azure Blob Storage, Azure Key Vault, optional external Vault, single-region enterprise install contract.
- [ ] The plan language is clearly BYOL and does not imply Microsoft-managed Terraform Enterprise licensing.
- [ ] Publisher name, application name, description, and version in `manifest.yaml` match the Partner Center record.
- [ ] Support contact, engineering escalation contact, privacy policy URL, and terms of use URL are populated in Partner Center.
- [ ] Preview audience subscriptions are selected and documented.

## Package Readiness

- [ ] `manifest.yaml` `version` uses `#.#.#` format and matches `BUNDLE_VERSION`.
- [ ] `manifest.yaml` `registryServer` points to the real publisher ACR, not `youracr.azurecr.io`.
- [ ] No blocking placeholders remain in `manifest.yaml`, `mainTemplate.json`, or `createUiDefinition.json`.
- [ ] No image in the chart remains on `latest`.
- [ ] `./scripts/verify.sh` passes.
- [ ] `./scripts/verify.sh --with-cpa` passes on a supported Linux/Windows AMD64 host.
- [ ] `./scripts/build-bundle.sh` completes successfully on a supported Linux/Windows AMD64 host.
- [ ] The final CNAB image reference, manifest version, and build date are recorded in the release notes for the preview build.

## Publisher ACR And Ingestion

- [ ] The publisher ACR is in the same Microsoft Entra tenant as the Partner Center publishing account.
- [ ] The first-party Marketplace ingestion service principal `32597670-3e15-4def-8851-614ff48c1efa` exists in the tenant.
- [ ] The Marketplace ingestion service principal has `acrpull` on the publisher ACR.
- [ ] The `Microsoft.PartnerCenterIngestion` resource provider is registered on the subscription that owns the publisher ACR.
- [ ] Docker authentication to the publisher ACR is verified before running `build-bundle.sh`.

## Preview Environment

- [ ] A clean AKS validation cluster exists for the preview dry run.
- [ ] The cluster is Linux-based and supports AMD64 workloads.
- [ ] No prior BYOL TFE Platform v1 cluster extension is installed on the validation cluster.
- [ ] External Secrets Operator with `external-secrets.io/v1` support is already installed.
- [ ] Azure Key Vault contains all required objects listed in `CUSTOMER-PREREQUISITES.md`.
- [ ] Workload identity is configured for the `azure-keyvault-reader` and `tfe-agent` service accounts.
- [ ] External PostgreSQL, Redis, Azure Blob Storage, DNS, and TLS prerequisites are ready before install starts.

## Dry-Run Install Procedure

1. Create or confirm the preview customer inputs from `CUSTOMER-VALUES-MATRIX.md`.
2. Submit the install from the Partner Center preview listing against the clean AKS cluster.
3. Budget 30-45 minutes for the first end-to-end dry run, including extension creation, ExternalSecret sync, image pulls, and Terraform Enterprise readiness.
4. Confirm the extension resource reaches a succeeded state in Azure before checking workload readiness.
5. Confirm the namespace exists and contains the expected resources.
6. Confirm ExternalSecret sync completed before troubleshooting Terraform Enterprise itself.

## Post-Install Acceptance Checks

Run these checks after the preview install completes:

```bash
kubectl get ns tfeplatform
kubectl get serviceaccount -n tfeplatform
kubectl get secretstore -n tfeplatform
kubectl get externalsecret -n tfeplatform
kubectl get secret -n tfeplatform
kubectl get deploy -n tfeplatform
kubectl get svc tfe -n tfeplatform -o wide
kubectl logs deploy/tfe -n tfeplatform --tail=100
kubectl logs deploy/tfe-agent -n tfeplatform --tail=100
curl -sk https://tfe.example.corp/_health_check
```

The preview dry run is acceptable only when all of the following are true:

- The namespace exists and contains `tfe`, `tfe-agent`, `azure-keyvault-reader`, `platform-config`, `tfe-config`, `tfe-agent-config`, `azure-keyvault`, and the expected ExternalSecret resources.
- The Kubernetes secrets `hc-pull-secret`, `tfe-secrets`, `tfe-agent-secrets`, and `tfe-tls` exist in the target namespace.
- The `tfe` deployment is `1/1` ready.
- The `tfe-agent` deployment is `1/1` ready.
- The `tfe` service is type `LoadBalancer` and has an ingress IP or hostname assigned.
- The install hostname resolves to the load balancer target.
- `/_health_check` returns a healthy response over HTTPS.

## First Triage Commands

Use these checks in order when the preview install fails:

| Symptom | First check | Command |
| --- | --- | --- |
| Namespace exists but secrets are missing | External Secrets status | `kubectl describe externalsecret -n tfeplatform` |
| ExternalSecret sync fails | SecretStore and workload identity | `kubectl describe secretstore azure-keyvault -n tfeplatform` |
| `tfe` pod does not start | Secret presence and TFE logs | `kubectl logs deploy/tfe -n tfeplatform --tail=200` |
| `tfe-agent` pod does not start | Agent secret and workload identity | `kubectl logs deploy/tfe-agent -n tfeplatform --tail=200` |
| Load balancer IP never appears | Service annotations and cluster networking | `kubectl describe svc tfe -n tfeplatform` |
| TLS health check fails | DNS and TLS secret content | `kubectl describe secret tfe-tls -n tfeplatform` |
| UI loads but TFE is unhealthy | Database, Redis, or object storage config | `kubectl logs deploy/tfe -n tfeplatform --tail=200` |

## Preview Blockers

Do not submit a preview build if any of these remain true:

- `manifest.yaml` still points at `youracr.azurecr.io`.
- CPA verification or bundle build has not been run on a supported host.
- The preview dry run has not completed on a clean AKS validation cluster.
- The docs in `CUSTOMER-PREREQUISITES.md` and `CUSTOMER-VALUES-MATRIX.md` do not match the current chart contract.
