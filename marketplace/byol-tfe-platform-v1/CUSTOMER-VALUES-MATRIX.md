# Customer Values Matrix

This matrix documents the install inputs and derived values for the BYOL TFE Platform v1 Marketplace package.

Column definitions:

- `Required` means required for a supported install path.
- `Source of truth` identifies where the contract is defined today.
- `Flow` describes whether the value comes from the Marketplace UI, ARM, Helm-only defaults, or secret material.

## Marketplace Parameters Not Passed To Helm

| Value name | Description | Required | Example | Source of truth | Flow |
| --- | --- | --- | --- | --- | --- |
| `clusterResourceName` | Existing AKS cluster name selected by the installer | Yes | `corp-aks-prod-01` | `createUiDefinition.json`, `mainTemplate.json` | UI -> ARM |
| `extensionResourceName` | Azure cluster extension resource name | Yes | `tfeplatform` | `createUiDefinition.json`, `mainTemplate.json` | UI -> ARM |
| `location` | Azure location of the target AKS resource | Yes | `eastus` | `createUiDefinition.json`, `mainTemplate.json` | UI -> ARM |

## Marketplace UI To ARM To Helm Values

| Value name | Description | Required | Example | Source of truth | Flow |
| --- | --- | --- | --- | --- | --- |
| `namespace` | Target namespace for the install | Yes | `tfeplatform` | `createUiDefinition.json`, `mainTemplate.json`, `chart/values.schema.json` | UI -> ARM -> Helm |
| `platformHostname` | Terraform Enterprise public hostname | Yes | `tfe.example.corp` | `createUiDefinition.json`, `mainTemplate.json`, `chart/values.schema.json` | UI -> ARM -> Helm |
| `serviceInternalLoadBalancer` | Whether the Azure load balancer is internal-only | Optional | `false` | `createUiDefinition.json`, `mainTemplate.json`, `chart/values.schema.json` | UI -> ARM -> Helm |
| `tfeStorageSizeGi` | Terraform Enterprise PVC size | Yes | `20Gi` | `createUiDefinition.json`, `mainTemplate.json`, `chart/values.schema.json` | UI -> ARM -> Helm |
| `keyVaultUrl` | Azure Key Vault URL used by the SecretStore | Yes | `https://example-keyvault.vault.azure.net` | `createUiDefinition.json`, `mainTemplate.json`, `chart/values.schema.json` | UI -> ARM -> Helm |
| `keyVaultClientId` | Client ID bound to the `azure-keyvault-reader` service account | Yes | `11111111-1111-1111-1111-111111111111` | `createUiDefinition.json`, `mainTemplate.json`, `chart/values.schema.json` | UI -> ARM -> Helm |
| `keyVaultTenantId` | Tenant ID used by the Key Vault workload identity | Yes | `22222222-2222-2222-2222-222222222222` | `createUiDefinition.json`, `mainTemplate.json`, `chart/values.schema.json` | UI -> ARM -> Helm |
| `armClientId` | Client ID bound to the `tfe-agent` service account | Yes | `33333333-3333-3333-3333-333333333333` | `createUiDefinition.json`, `mainTemplate.json`, `chart/values.schema.json` | UI -> ARM -> Helm |
| `armTenantId` | Tenant ID used by the Terraform Enterprise agent | Yes | `22222222-2222-2222-2222-222222222222` | `createUiDefinition.json`, `mainTemplate.json`, `chart/values.schema.json` | UI -> ARM -> Helm |
| `armSubscriptionId` | Subscription ID used by the Terraform Enterprise agent | Yes | `44444444-4444-4444-4444-444444444444` | `createUiDefinition.json`, `mainTemplate.json`, `chart/values.schema.json` | UI -> ARM -> Helm |
| `databaseHost` | External PostgreSQL endpoint in `host:port` form | Yes | `postgres.example.corp:5432` | `createUiDefinition.json`, `mainTemplate.json`, `chart/values.schema.json` | UI -> ARM -> Helm |
| `databaseName` | PostgreSQL database name | Yes | `tfe` | `createUiDefinition.json`, `mainTemplate.json`, `chart/values.schema.json` | UI -> ARM -> Helm |
| `databaseUser` | PostgreSQL username | Yes | `tfe` | `createUiDefinition.json`, `mainTemplate.json`, `chart/values.schema.json` | UI -> ARM -> Helm |
| `databaseParameters` | PostgreSQL connection parameters | Yes | `sslmode=require` | `createUiDefinition.json`, `mainTemplate.json`, `chart/values.schema.json` | UI -> ARM -> Helm |
| `redisUrl` | External Redis connection URL | Yes | `redis://redis.example.corp:6379` | `createUiDefinition.json`, `mainTemplate.json`, `chart/values.schema.json` | UI -> ARM -> Helm |
| `objectStorageAccountName` | Azure Storage account name for object storage | Yes | `exampleaccount` | `createUiDefinition.json`, `mainTemplate.json`, `chart/values.schema.json` | UI -> ARM -> Helm |
| `objectStorageContainer` | Azure Blob container name for object storage | Yes | `tfestate` | `createUiDefinition.json`, `mainTemplate.json`, `chart/values.schema.json` | UI -> ARM -> Helm |
| `agentLogLevel` | Terraform Enterprise agent log level | Yes | `info` | `createUiDefinition.json`, `mainTemplate.json`, `chart/values.schema.json` | UI -> ARM -> Helm |
| `vaultEnabled` | Toggle for external Vault integration | Optional | `false` | `createUiDefinition.json`, `mainTemplate.json`, `chart/values.schema.json` | UI -> ARM -> Helm |
| `vaultAddress` | External Vault API address | Conditional | `https://vault.example.corp:8200` | `createUiDefinition.json`, `mainTemplate.json`, `chart/values.schema.json` | UI -> ARM -> Helm |
| `vaultClusterAddress` | External Vault cluster address | Conditional | `https://vault.example.corp:8201` | `createUiDefinition.json`, `mainTemplate.json`, `chart/values.schema.json` | UI -> ARM -> Helm |
| `vaultAuthMethod` | Vault auth method supported by the chart | Conditional | `kubernetes` | `createUiDefinition.json`, `mainTemplate.json`, `chart/values.schema.json` | UI -> ARM -> Helm |
| `vaultRole` | Vault role used when Vault integration is enabled | Conditional | `tfe-agent` | `createUiDefinition.json`, `mainTemplate.json`, `chart/values.schema.json` | UI -> ARM -> Helm |

## Derived And Helm-Only Values

| Value name | Description | Required | Example | Source of truth | Flow |
| --- | --- | --- | --- | --- | --- |
| `createNamespace` | Instructs the chart to create the target namespace | Yes (defaulted) | `true` | `mainTemplate.json`, `chart/values.yaml` | ARM constant -> Helm |
| `serviceType` | Kubernetes service type for Terraform Enterprise | Yes (fixed) | `LoadBalancer` | `mainTemplate.json`, `chart/values.schema.json` | ARM constant -> Helm |
| `tfeStorageClassName` | Storage class override for the Terraform Enterprise PVC | Optional | `managed-csi` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |
| `externalSecretsRefreshInterval` | ExternalSecret refresh interval | Yes (defaulted) | `1h` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |
| `armUseOidc` | Enables OIDC for Azure authentication | Yes (defaulted) | `true` | `chart/values.yaml` | Helm only |
| `armUseCli` | Enables Azure CLI auth fallback | Yes (defaulted) | `false` | `chart/values.yaml` | Helm only |
| `agentTfcAddress` | Terraform Cloud/Enterprise address used by the agent | Yes (derived) | `https://tfe.example.corp` | `mainTemplate.json`, `chart/templates/_helpers.tpl` | Derived in ARM -> Helm |
| `agentImagePullPolicy` | Pull policy for the agent container | Yes (defaulted) | `IfNotPresent` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |
| `tfeVaultDisableMlock` | Terraform Enterprise Vault mlock toggle | Optional | `true` | `chart/values.yaml` | Helm only |
| `tfeReplicaCount` | Terraform Enterprise replica count | Yes (fixed) | `1` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |
| `agentReplicaCount` | Agent replica count | Yes (fixed) | `1` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |
| `kubernetesPullSecretName` | Kubernetes image pull secret name | Yes (defaulted) | `hc-pull-secret` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |
| `kubernetesTfeSecretName` | Kubernetes secret name for Terraform Enterprise env vars | Yes (defaulted) | `tfe-secrets` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |
| `kubernetesTfeAgentSecretName` | Kubernetes secret name for agent env vars | Yes (defaulted) | `tfe-agent-secrets` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |
| `kubernetesTlsSecretName` | Kubernetes TLS secret name for Terraform Enterprise | Yes (defaulted) | `tfe-tls` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |
| `keyVaultTfeSecretName` | Key Vault object name for Terraform Enterprise secret material | Yes (defaulted) | `tfe-secrets` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |
| `keyVaultTfeAgentSecretName` | Key Vault object name for agent secret material | Yes (defaulted) | `tfe-agent-secrets` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |
| `keyVaultTlsCrtSecretName` | Key Vault object name for the TLS certificate | Yes (defaulted) | `tfe-tls-crt` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |
| `keyVaultTlsKeySecretName` | Key Vault object name for the TLS private key | Yes (defaulted) | `tfe-tls-key` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |
| `keyVaultPullSecretName` | Key Vault object name for the Docker pull secret | Yes (defaulted) | `hc-pull-secret` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |

## Resource Defaults

| Value name | Description | Required | Example | Source of truth | Flow |
| --- | --- | --- | --- | --- | --- |
| `tfeResources.requests.memory` | Terraform Enterprise memory request | Optional | `3Gi` | `chart/values.yaml` | Helm only |
| `tfeResources.requests.cpu` | Terraform Enterprise CPU request | Optional | `350m` | `chart/values.yaml` | Helm only |
| `tfeResources.limits.memory` | Terraform Enterprise memory limit | Optional | `4Gi` | `chart/values.yaml` | Helm only |
| `tfeResources.limits.cpu` | Terraform Enterprise CPU limit | Optional | `2000m` | `chart/values.yaml` | Helm only |
| `agentResources.requests.cpu` | Agent CPU request | Optional | `50m` | `chart/values.yaml` | Helm only |
| `agentResources.requests.memory` | Agent memory request | Optional | `128Mi` | `chart/values.yaml` | Helm only |
| `agentResources.limits.cpu` | Agent CPU limit | Optional | `300m` | `chart/values.yaml` | Helm only |
| `agentResources.limits.memory` | Agent memory limit | Optional | `512Mi` | `chart/values.yaml` | Helm only |

## Image Defaults

| Value name | Description | Required | Example | Source of truth | Flow |
| --- | --- | --- | --- | --- | --- |
| `global.azure.images.tfe.registry` | Terraform Enterprise image registry path | Yes (defaulted) | `crest.azurecr.io` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |
| `global.azure.images.tfe.image` | Terraform Enterprise image name | Yes (defaulted) | `terraform-enterprise` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |
| `global.azure.images.tfe.tag` | Terraform Enterprise image tag | Yes (defaulted) | `v202501-1` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |
| `global.azure.images.tfe.digest` | Terraform Enterprise image digest override | Optional | `sha256:53a98c93d4f5e6655b439569d7fce717521e4e5655e3cf4ee107d0536fb47f0d` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |
| `global.azure.images.tfeAgent.registry` | Terraform Enterprise agent image registry path | Yes (defaulted) | `crest.azurecr.io/hashicorp` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |
| `global.azure.images.tfeAgent.image` | Terraform Enterprise agent image name | Yes (defaulted) | `tfc-agent` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |
| `global.azure.images.tfeAgent.tag` | Terraform Enterprise agent image tag | Yes (defaulted) | `1.28.10` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |
| `global.azure.images.tfeAgent.digest` | Terraform Enterprise agent image digest override | Optional | `sha256:2a910a85203760d84de8da4a95d839599cb50253cfac1f4ed23a6bd94dd8f5f4` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |
| `global.azure.images.tlsInit.registry` | TLS init container image registry path | Yes (defaulted) | `crest.azurecr.io/library` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |
| `global.azure.images.tlsInit.image` | TLS init container image name | Yes (defaulted) | `busybox` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |
| `global.azure.images.tlsInit.tag` | TLS init container image tag | Yes (defaulted) | `1.37.0` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |
| `global.azure.images.tlsInit.digest` | TLS init container image digest override | Optional | `sha256:7a634b8e555c3f394551ae422325e7f9d9d1420e8ac7e8f7ac6ce311dca91b0d` | `chart/values.yaml`, `chart/values.schema.json` | Helm only |

## Secret Material Passed Through External Secrets

| Secret material | Description | Required | Example | Source of truth | Flow |
| --- | --- | --- | --- | --- | --- |
| `hc-pull-secret.dockerconfigjson` | Docker auth config used to pull the mirrored runtime images from `crest.azurecr.io` | Yes | JSON docker config payload | `chart/templates/externalsecrets.yaml` | Key Vault -> ExternalSecret -> Kubernetes secret |
| `tfe-secrets.TFE_LICENSE` | Terraform Enterprise license value | Yes | Customer license string | `README.md`, `chart/templates/externalsecrets.yaml` | Key Vault -> ExternalSecret -> Kubernetes secret |
| `tfe-secrets.TFE_ENCRYPTION_PASSWORD` | Terraform Enterprise encryption password | Yes | Redacted | `README.md`, `chart/templates/externalsecrets.yaml` | Key Vault -> ExternalSecret -> Kubernetes secret |
| `tfe-secrets.TFE_DATABASE_PASSWORD` | PostgreSQL password for Terraform Enterprise | Yes | Redacted | `README.md`, `chart/templates/externalsecrets.yaml` | Key Vault -> ExternalSecret -> Kubernetes secret |
| `tfe-secrets.TFE_OBJECT_STORAGE_AZURE_ACCOUNT_KEY` | Azure Storage account key for object storage | Yes | Redacted | `README.md`, `chart/templates/externalsecrets.yaml` | Key Vault -> ExternalSecret -> Kubernetes secret |
| `tfe-secrets.TFE_VAULT_TOKEN` | Vault token expected by the current Terraform Enterprise secret payload | Yes | Redacted | `README.md`, `chart/templates/externalsecrets.yaml` | Key Vault -> ExternalSecret -> Kubernetes secret |
| `tfe-agent-secrets.TFC_AGENT_TOKEN` | Token used by the Terraform Enterprise agent | Yes | Redacted | `README.md`, `chart/templates/externalsecrets.yaml` | Key Vault -> ExternalSecret -> Kubernetes secret |
| `tfe-tls-crt` | PEM certificate chain | Yes | PEM payload | `chart/templates/externalsecrets.yaml` | Key Vault -> ExternalSecret -> Kubernetes TLS secret |
| `tfe-tls-key` | PEM private key | Yes | PEM payload | `chart/templates/externalsecrets.yaml` | Key Vault -> ExternalSecret -> Kubernetes TLS secret |
