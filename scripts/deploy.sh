#!/usr/bin/env bash
# Deploy the stack to Azure. Requires: az CLI, an Azure subscription,
# and a resource group. Usage:
#   ./scripts/deploy.sh <resource-group> [dev|prod]
set -euo pipefail

RG="${1:?Usage: ./scripts/deploy.sh <resource-group> [dev|prod]}"
ENV="${2:-dev}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

az group create --name "$RG" --location eastus --output none
az deployment group create \
  --resource-group "$RG" \
  --template-file "$ROOT/infra/main.bicep" \
  --parameters "$ROOT/infra/main.${ENV}.bicepparam"

echo "--- outputs ---"
az deployment group show --resource-group "$RG" --name main \
  --query properties.outputs --output table
