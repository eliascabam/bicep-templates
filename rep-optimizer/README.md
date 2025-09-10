# rep-optimizer Infrastructure

This folder provides a modular Azure Bicep deployment for the **rep-optimizer** project. Each Azure resource is defined in its own module and orchestrated through `main.bicep`.

## Modules

| Module | Purpose |
|--------|---------|
| `modules/resource-group.bicep` | Creates the resource group that hosts all resources. |
| `modules/managed-identity.bicep` | User-assigned managed identity for the compute workload. |
| `modules/vnet.bicep` | Virtual network with subnets for compute and private endpoints. |
| `modules/container-registry.bicep` | Azure Container Registry to store the container image. |
| `modules/storage-account.bicep` | ADLS Gen2 storage account with private endpoint. |
| `modules/key-vault.bicep` | Key Vault containing `ADLSAcctName` and `ADLSAcctKey` secrets. |
| `modules/log-analytics.bicep` | Log Analytics workspace for diagnostics. |
| `modules/app-insights.bicep` | Application Insights linked to the workspace. |
| `modules/container-instance.bicep` | Azure Container Instance with managed identity and environment flags. |

## Deployment

Deploy the infrastructure at the subscription scope. Provide environment-specific values for all resource names and parameters.

```bash
# Example deployment
az deployment sub create \
  --location <location> \
  --template-file main.bicep \
  --parameters \
      location=<location> \
      rgName=<rg-name> \
      vnetName=<vnet-name> \
      acrName=<acr-name> \
      containerGroupName=<aci-name> \
      storageAccountName=<storage-name> \
      keyVaultName=<kv-name> \
      logAnalyticsName=<law-name> \
      appInsightsName=<ai-name> \
      tenantId=<tenant-guid> \
      imageName=rep-optimizer:latest \
      adlsAcctName=<adls-account-name> \
      adlsAcctKey=<adls-account-key>
```

Outputs include the container registry login server, key vault URI, storage account ID, and the principal ID of the managed identity.

## Application Build

Build the container image for rep-optimizer:

```bash
# from repo root
docker build --pull --no-cache -t rep-optimizer:latest .
```

## Run Examples

### Windows PowerShell
```powershell
$stores = "T003,T005,T007,T009,T010,T014,T017,T018,T019,T020,T022,T024,T025,T027,T028,T029,T030,T033,T034,T035,T036,T037,T038,T039,T041,T042,T043,T044,T045,T046"

docker run -it --rm `
  --env-file "C:\Users\ecaba\Documents\rep\rails.txt" `
  --cpus 4 -m 8g `
  -e STORES_FILTER="$stores" `
  -e HIGHS_USE_PERSISTENT=1 `
  -e HIGHS_METHOD=dual `
  -e HIGHS_THREADS=4 `
  -e HIGHS_TIME_LIMIT_SEC=0 `
  -e SHOW_OUTPUT_PREVIEW=0 `
  -e DELTA_LIST_LOGS=0 `
  rep-optimizer:latest
```

### macOS/Linux
```bash
stores="T003,T005,T007,..."   # comma-separated
docker run -it --rm \
  --env-file "$HOME/rep/rails.txt" \
  --cpus 4 -m 8g \
  -e STORES_FILTER="$stores" \
  -e HIGHS_USE_PERSISTENT=1 \
  -e HIGHS_METHOD=dual \
  -e HIGHS_THREADS=4 \
  -e HIGHS_TIME_LIMIT_SEC=0 \
  -e SHOW_OUTPUT_PREVIEW=0 \
  -e DELTA_LIST_LOGS=0 \
  rep-optimizer:latest
```

## Required Secrets

The Key Vault must contain the following secrets:

- **ADLSAcctName** – Storage account name.
- **ADLSAcctKey** – Storage account key.

The container expects an environment file with:

- `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_CLIENT_SECRET` – service principal credentials with *Key Vault Secrets User* role.
- `KEY_VAULT_NAME` – name of the Key Vault deployed above.
- `AZURE_CONTAINER_NAME` – target ADLS container.
- Optional: `PARAMETERS_PATH`, `CAPACITY_PATH`.

## Runtime Flags

- `STORES_FILTER` – comma-separated store codes; empty runs all stores.
- `SHOW_OUTPUT_PREVIEW` – `0` or `1` to print a preview of results.
- `DELTA_LIST_LOGS` – `0` or `1` to list Delta log entries.

### HiGHS Solver

- `HIGHS_USE_PERSISTENT` – `1` to use persistent solver.
- `HIGHS_METHOD` – `dual` (baseline), `simplex`, or `ipm`.
- `HIGHS_THREADS` – number of solver threads.
- `HIGHS_TIME_LIMIT_SEC` – wall-time limit (`0` = unlimited).

Baseline defaults:
`HIGHS_USE_PERSISTENT=1`, `HIGHS_METHOD=dual`, `HIGHS_THREADS=4`, `HIGHS_TIME_LIMIT_SEC=0`, `SHOW_OUTPUT_PREVIEW=0`, `DELTA_LIST_LOGS=0`.

