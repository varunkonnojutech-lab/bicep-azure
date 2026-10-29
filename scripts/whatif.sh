#!/usr/bin/env bash
# Preview what a deployment would change, without changing anything.
# Usage: ./scripts/whatif.sh <resource-group> [dev|prod]
set -euo pipefail

RG="${1:?Usage: ./scripts/whatif.sh <resource-group> [dev|prod]}"
ENV="${2:-dev}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

az deployment group what-if \
  --resource-group "$RG" \
  --template-file "$ROOT/infra/main.bicep" \
  --parameters "$ROOT/infra/main.${ENV}.bicepparam"
