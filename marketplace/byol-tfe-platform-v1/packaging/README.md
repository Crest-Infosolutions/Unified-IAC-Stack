# Packaging Workflow

This directory documents the local and CI packaging flow for the BYOL TFE Platform v1 Marketplace offer.

## What The Scripts Do

- `scripts/verify.sh` runs local preflight checks and can also invoke `cpa verify`.
- `scripts/build-bundle.sh` reruns preflight checks and then invokes `cpa buildbundle`.
- `scripts/common.sh` contains shared environment loading, guardrails, and CPA container execution logic.

## Prerequisites

- `helm`
- `jq`
- `git`
- `docker` or `podman`
- A publisher Azure Container Registry in the same Microsoft Entra tenant as Partner Center
- Container runtime authentication to the publisher ACR before `build-bundle.sh`

Microsoft documents CPA packaging support for Linux/Windows AMD64 hosts. Local preflight validation is shell-based and can run on macOS, but the CPA-backed steps should be executed on a supported host or Linux CI runner.

## Environment Setup

Copy `.env.example` to `.env` inside the package root and populate these values:

- `REGISTRY_NAME`: publisher ACR name without the domain
- `REGISTRY_SERVER`: publisher ACR login server, for example `contoso.azurecr.io`
- `BUNDLE_VERSION`: Marketplace package version and `manifest.yaml` version
- `MARKETPLACE_PACKAGE_DIR`: absolute path to this package directory

Optional values:

- `CPA_IMAGE`: defaults to `mcr.microsoft.com/container-package-app:latest`
- `CPA_CONTAINER_SOCKET`: optional explicit Docker-compatible socket path to mount into the CPA container
- `HELM_RELEASE_NAME`: defaults to `byol-tfe-platform`
- `VALUES_FILE`: defaults to `examples/values.enterprise.example.yaml`
- `ALLOW_UNSUPPORTED_HOST`: override for trying CPA steps on unsupported hosts

## Local Verification

Run the local preflight checks:

```bash
./scripts/verify.sh
```

That command enforces the following guardrails:

- `manifest.yaml` version must use `#.#.#` format
- `manifest.yaml` version must match `BUNDLE_VERSION`
- `manifest.yaml` `registryServer` must match `REGISTRY_SERVER`
- blocking placeholders such as `youracr.azurecr.io` must be removed
- no chart image may remain on `latest`
- `helm lint` must pass for the selected values file
- `helm template` must render for the selected values file and the Partner Center example values file
- `jq empty` must pass for `mainTemplate.json` and `createUiDefinition.json`

To also run the Microsoft packaging tool verification stage on a supported host:

```bash
./scripts/verify.sh --with-cpa
```

## GitHub Actions Workflow

The repository workflow at `.github/workflows/marketplace-package.yml` uses the same shell scripts instead of duplicating packaging logic in YAML.

- The `verify` job runs on `pull_request`, `push` to `main`, and `workflow_dispatch`.
- The `buildbundle` job runs only from `workflow_dispatch` when `run_buildbundle=true`.
- The workflow derives `BUNDLE_VERSION`, `REGISTRY_SERVER`, and `REGISTRY_NAME` from `manifest.yaml` before invoking the scripts.

Credential requirements:

- No Microsoft cloud credentials are required for the plain `verify` job.
- The `verify` job still enforces the real package contract, so it will fail until `manifest.yaml` stops using the placeholder `youracr.azurecr.io` registry.
- Microsoft cloud credentials are required for the manual `buildbundle` job because it performs Azure login and `az acr login` before running `cpa verify` and `cpa buildbundle`.
- The workflow expects GitHub secrets named `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` for OIDC-backed Azure login.

## Build The CNAB Bundle

Authenticate your selected container runtime to your publisher ACR first, then run:

```bash
./scripts/build-bundle.sh
```

To overwrite an existing bundle tag during dry-run packaging only:

```bash
./scripts/build-bundle.sh --force
```

The build script pulls `mcr.microsoft.com/container-package-app:latest`, mounts the Marketplace package at `/data`, and runs `cpa buildbundle` inside the packaging container using `docker` when available and `podman` otherwise.

## Required Azure Setup For Ingestion

Microsoft Marketplace deep-copies your CNAB from your publisher ACR. The required first-party application ID is `32597670-3e15-4def-8851-614ff48c1efa`.

Grant the service principal `acrpull` access to your registry:

```bash
az ad sp show --id 32597670-3e15-4def-8851-614ff48c1efa
az ad sp create --id 32597670-3e15-4def-8851-614ff48c1efa
az acr show --name <registry-name> --query id --output tsv
az role assignment create --assignee <sp-id> --scope <registry-id> --role acrpull
```

Register the Partner Center ingestion provider on the subscription that owns the ACR:

```bash
az provider register --namespace Microsoft.PartnerCenterIngestion --subscription <subscription-id> --wait
az provider show -n Microsoft.PartnerCenterIngestion --subscription <subscription-id>
```

## Notes

- `buildbundle` already runs verification internally, but the wrapper keeps the local preflight checks explicit and fail-fast.
- The version bump check is best-effort. If the package is new and `manifest.yaml` is not in `HEAD` yet, the script skips that specific check and prints a warning.
- CPA steps prefer `docker` when present and fall back to `podman`. If bundle build needs a Docker-compatible socket on a podman host, set `CPA_CONTAINER_SOCKET` explicitly.
- Marketplace-prescribed `DONOTMODIFY` plan placeholders in `mainTemplate.json` are allowed and are not treated as blocking placeholders.
