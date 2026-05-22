# BYOL TFE Platform v1 Implementation Plan

This plan is ordered for the fastest path to a sellable v1 Marketplace offer.

## v1 Target

The v1 offer is a narrow BYOL Terraform Enterprise platform for Azure Kubernetes Service.

Supported scope:

- Existing AKS cluster only
- Single region
- Multi-AZ capable cluster topology
- External PostgreSQL
- External Redis
- Azure Blob Storage for TFE object storage
- Azure Key Vault with External Secrets
- Terraform Enterprise agent included
- Optional external Vault integration

Deferred from v1:

- New-cluster creation path
- Multi-region failover
- Bundled Vault, PostgreSQL, and Redis
- Optional infra and config job packages
- Full Packer and Ansible product packaging

## Sequence

1. Harden the v1 chart for a stricter enterprise install contract.
2. Add packaging and verification automation for `cpa verify` and `cpa buildbundle`.
3. Create the Partner Center preview checklist and the customer prerequisite and values matrix.

## Phase 1: Harden The v1 Chart

### Phase 1 Goal

Turn the current Marketplace chart into a strict enterprise install surface with fewer unsupported combinations, stronger defaults, clearer prerequisites, and repeatable validation.

### Phase 1 Why This Comes First

The Marketplace packaging layer is only useful if the chart underneath is the exact supported product. Hardening the chart first avoids packaging an unstable contract.

### Phase 1 Scope

Files already in scope:

- `marketplace/byol-tfe-platform-v1/chart/values.yaml`
- `marketplace/byol-tfe-platform-v1/chart/templates/configmaps.yaml`
- `marketplace/byol-tfe-platform-v1/chart/templates/externalsecrets.yaml`
- `marketplace/byol-tfe-platform-v1/chart/templates/pvc.yaml`
- `marketplace/byol-tfe-platform-v1/chart/templates/tfe.yaml`
- `marketplace/byol-tfe-platform-v1/chart/templates/tfe-agent.yaml`
- `marketplace/byol-tfe-platform-v1/createUiDefinition.json`
- `marketplace/byol-tfe-platform-v1/mainTemplate.json`

### Phase 1 Work Items

1. Narrow the supported configuration surface.
   - Remove or hide options that are not actually supportable in v1.
   - Keep `existing AKS cluster only` as the contract.
   - Decide whether `ClusterIP` remains supported or whether v1 requires `LoadBalancer`.
   - Decide whether external Vault remains optional or becomes out of scope for the first listing.

2. Replace weak defaults with enterprise defaults.
   - Pin all images to immutable tags or digests.
   - Remove `latest` tags from the chart defaults.
   - Increase storage and resource defaults to values appropriate for a serious evaluation environment.
   - Add explicit storage class handling guidance.

3. Add guardrails to the Helm chart.
   - Fail early on missing required values using Helm template validation.
   - Add a `values.schema.json` file for required keys, types, enums, and patterns.
   - Add validation for hostnames, Key Vault URLs, GUIDs, database endpoints, and storage account naming.

4. Tighten workload security and runtime expectations.
   - Review `allowPrivilegeEscalation`, root execution, and any capability adds that are still required.
   - Add pod security context defaults where safe.
   - Add annotations or notes for Azure internal load balancer support if that stays in scope.
   - Decide whether the chart should install a PodDisruptionBudget for the agent.

5. Clarify the network and exposure contract.
   - Decide whether v1 requires a load balancer or expects ingress to be handled externally.
   - If ingress is not bundled, document that clearly and keep the chart service model simple.
   - If the service remains `LoadBalancer`, define internal versus external exposure guidance.

6. Add chart examples and operator-facing values files.
   - Create `values.enterprise.example.yaml` with a fully populated example.
   - Create `values.partnercenter.example.yaml` matching the values passed from `mainTemplate.json`.

7. Expand local validation.
   - Add render tests for at least two supported configurations.
   - Validate that the chart still renders when Vault is disabled.
   - Validate that all expected secrets and config maps are produced with deterministic names.

### Phase 1 Deliverables

- Hardened Helm chart
- `values.schema.json`
- Example values files
- Updated UI and ARM parameters to match the final support boundary

### Phase 1 Exit Criteria

- Chart defaults contain no mutable image tags.
- Chart renders only supported v1 configurations.
- Required values are schema-validated.
- Install contract is narrower and documented.

## Phase 2: Packaging And Verification Automation

### Phase 2 Goal

Create a repeatable packaging flow that validates the Marketplace artifacts, packages the CNAB, and reduces operator mistakes before preview submission.

### Phase 2 Why This Comes Second

The packaging pipeline should encode the final chart contract, not chase changing inputs.

### Phase 2 Scope

New files to create:

- `marketplace/byol-tfe-platform-v1/scripts/verify.sh`
- `marketplace/byol-tfe-platform-v1/scripts/build-bundle.sh`
- `marketplace/byol-tfe-platform-v1/scripts/common.sh`
- `marketplace/byol-tfe-platform-v1/.env.example`
- `marketplace/byol-tfe-platform-v1/packaging/README.md`

Optional follow-up:

- `.github/workflows/marketplace-package.yml`

### Phase 2 Work Items

1. Define the script contract.
   - Required environment variables:
     - `REGISTRY_NAME`
     - `REGISTRY_SERVER`
     - `BUNDLE_VERSION`
     - `MARKETPLACE_PACKAGE_DIR`
   - Optional environment variables:
     - `CPA_IMAGE`
     - `HELM_RELEASE_NAME`
     - `VALUES_FILE`

2. Build a local verification script.
   - Run `helm lint`.
   - Run `helm template` with a supported example values file.
   - Run `jq empty` on `mainTemplate.json` and `createUiDefinition.json`.
   - Validate `manifest.yaml` version format.
   - Check that `registryServer` matches the configured registry.
   - Check that no known placeholder strings remain.

3. Build a bundle packaging script.
   - Pull `mcr.microsoft.com/container-package-app:latest`.
   - Mount the Marketplace package directory into the packaging container.
   - Run `cpa verify`.
   - Run `cpa buildbundle`.
   - Surface bundle tags and ACR output clearly.

4. Add safe failure behavior.
   - Exit on unset variables and command failures.
   - Fail if the Marketplace version was not bumped.
   - Fail if any image remains on `latest`.

5. Add documentation for the packaging flow.
   - Show one local verification command.
   - Show one bundle build command.
   - Document the required ACR role assignments and Partner Center ingestion setup.

### Phase 2 Deliverables

- Packaging scripts
- `.env.example`
- Packaging usage documentation

### Phase 2 Exit Criteria

- A single command verifies the package locally.
- A single command builds the CNAB bundle to the publisher ACR.
- Scripts fail fast on placeholders, mutable tags, and missing environment variables.

## Phase 3: Partner Center Preview Checklist And Customer Matrix

### Phase 3 Goal

Create the exact preview readiness checklist and customer-facing install inputs needed to run a limited preview without back-and-forth discovery.

### Phase 3 Why This Comes Third

The preview checklist and customer matrix must reflect the actual hardened chart and the actual packaging flow.

### Phase 3 Scope

New files to create:

- `marketplace/byol-tfe-platform-v1/PARTNER-CENTER-PREVIEW-CHECKLIST.md`
- `marketplace/byol-tfe-platform-v1/CUSTOMER-PREREQUISITES.md`
- `marketplace/byol-tfe-platform-v1/CUSTOMER-VALUES-MATRIX.md`
- `marketplace/byol-tfe-platform-v1/examples/values.enterprise.example.yaml`

### Phase 3 Work Items

1. Create the Partner Center preview checklist.
   - Offer metadata complete
   - Support contact complete
   - Privacy policy and legal terms linked
   - Plan metadata aligned with BYOL strategy
   - ACR ingestion permissions configured
   - Bundle built and recorded
   - Preview audience subscriptions selected
   - Dry-run install completed on clean AKS subscription

2. Create the customer prerequisites matrix.
   - AKS version and cluster requirements
   - Namespace behavior
   - External Secrets Operator requirement
   - Azure Key Vault objects required
   - Federated identities required
   - External PostgreSQL requirements
   - External Redis requirements
   - Azure Blob storage requirements
   - Optional external Vault requirements
   - DNS and certificate requirements

3. Create the exact values matrix.
   - Each value name
   - Description
   - Required or optional
   - Example value
   - Source of truth
   - Whether it is passed through UI, ARM, or secret material

4. Create preview operator guidance.
   - Expected install duration
   - Post-install validation steps
   - Known failure modes
   - Exact logs and resources to inspect first

### Phase 3 Deliverables

- Partner Center preview checklist
- Customer prerequisites matrix
- Customer values matrix
- Example values file aligned to the final chart

### Phase 3 Exit Criteria

- A preview customer can gather every prerequisite without asking for hidden context.
- A partner operator can submit and test the preview offer with a single checklist.
- All exposed inputs are documented once and consistently across UI, ARM, Helm, and docs.

## Recommended Execution Order Inside The Repo

1. Update chart defaults and validations.
2. Add `values.schema.json`.
3. Add example values files.
4. Align `createUiDefinition.json` and `mainTemplate.json` to the hardened contract.
5. Add packaging scripts.
6. Add preview and customer documentation.

## Risks To Control Early

- Marketplace packaging succeeds while the install contract is still too loose.
- The offer exposes options that the support model cannot actually honor.
- Image pinning is deferred too long and blocks certification late.
- External prerequisite documentation drifts from the real chart inputs.

## Definition Of Ready For Preview

The package is ready for Partner Center preview when all of the following are true:

- The chart supports only the intended v1 architecture.
- The chart, UI, ARM template, and docs share one consistent parameter model.
- Packaging scripts verify and build the CNAB reproducibly.
- Customer prerequisites and values are documented in operator-ready form.
- No placeholders, mutable tags, or undeclared dependencies remain in the package.
