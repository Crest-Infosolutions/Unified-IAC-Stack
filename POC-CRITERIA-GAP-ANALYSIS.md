# POC Criteria Gap Analysis

Source reviewed on 2026-05-22: repo-root `criteria.docx`.

## Scope

- Criteria themes:
  - Phase 1 Terraform operating model and governance
  - Phase 2 Vault JIT access and audit
  - Phase 3 FinOps and tooling

## Current Repo Position

- Current repo is primarily a TFE-on-AKS platform package, not a full Terraform estate.
- Strongest implemented areas are:
  - AKS deployment packaging
  - Terraform Enterprise agent
  - Azure Key Vault via External Secrets
  - Azure workload identity and OIDC foundations
  - Optional external Vault integration
  - Optional Terraform, Packer, and Ansible job hooks

## Evidence Anchors

- `README.md`
- `.github/workflows/marketplace-package.yml`
- `jobs/infra/job.yaml`
- `jobs/config/job.yaml`
- `jobs/infra/config/job.env`
- `jobs/config/config/job.env`

## Likely Supported Or Partly Supported

- Azure OIDC foundation
- TFE agent execution foundation
- Vault auth and secret retrieval foundation
- Optional Packer hook
- Dedicated service accounts and workload identity separation

## Clearly Missing In This Repo Today

- No Terraform module code in the workspace
- No semantic version or private registry enforcement for modules
- No strict module version pinning checks
- No ephemeral self-hosted runners
- No plan/apply separation of duties
- No PIM gate
- No AWS orchestration example
- No on-prem demo workflow
- No state backend or object lock/versioning setup
- No drift detection ticketing
- No Sentinel, OPA, or Conftest policies
- No Vault dynamic secrets, revocation, or audit sink implementation
- No Infracost PR comments
- No cost guardrails
- No mandatory-tag policy
- No budget-as-code or Action Groups implementation

## Important Caveats

- `jobs/infra/job.yaml` currently does `terraform plan` and then `terraform apply -auto-approve`; this conflicts with the criteria separation-of-duties goal.
- `README.md` notes that the Vault bootstrap and runtime auth flow is not complete yet.
- `README.md` also notes that the optional job image is still a placeholder.

## Best Future Implementation Paths

1. Treat this repo as the platform repo and add companion repos for landing-zone modules, workload-live config, policy bundles, and Packer images.
2. For a fast POC, add minimal demo assets around this repo: Azure and AWS Terraform examples, plan/apply split workflow, OPA or Sentinel checks, drift detection, Infracost, budget and tagging controls, Vault dynamic secret demo, and audit export.

## Return Path

- When returning to this, start by turning the criteria into a status matrix: met, partial, or missing, with repo evidence and a smallest-credible remediation for each item.
