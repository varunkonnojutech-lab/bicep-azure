# Bicep on Azure — APIM + Function App, the Terraform alternative

[![Build](https://github.com/varunkonnojutech-lab/bicep-azure/actions/workflows/ci.yml/badge.svg)](https://github.com/varunkonnojutech-lab/bicep-azure/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Bicep](https://img.shields.io/badge/Bicep-Azure-0078D4)](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/varunkonnojutech-lab/bicep-azure)

Terraform is the cross-cloud default, but if your cloud is Azure, Bicep is the native answer: it compiles to ARM templates, understands Azure resource types first-hand, and needs no state file, no provider plugins, and no `terraform init`. This repo is the Bicep counterpart to [`terraform-azure`](https://github.com/varunkonnojutech-lab/terraform-azure) in this portfolio — the same kind of workload, expressed the Azure-native way, with one extra piece Terraform's version doesn't have: API Management in front of the app.

The stack: a .NET 8 Function App (isolated worker) behind API Management, with a Storage account, Application Insights, and a Key Vault the function reads via its managed identity — no passwords or connection strings anywhere in configuration.

## Who is this for

.NET developers who deploy to Azure and have only ever clicked through the portal — or who know Terraform and want to see what the Azure-native tool looks like on the same problem. If "infrastructure as code" is on your resume, this is the repo that proves the Azure side of it.

## What you'll learn

- **Bicep fundamentals** — parameters, modules, symbolic names, and `existing` resources, with no state file to babysit
- **Modular templates** — one module per concern (storage, insights, vault, function, APIM), composed in `main.bicep`
- **Parameter files** — dev vs prod as data (`.bicepparam`), not as copied templates: prod differs only in the APIM SKU
- **Managed identities + RBAC** — the Function App reads Key Vault secrets with its system-assigned identity and a single role assignment, no access policies, no secrets in app settings
- **APIM as a front door** — an API, its operations, and a policy (rate-limit per IP + CORS) standing between callers and the function
- **Safe deploys** — `what-if` previews before every apply, and CI that compiles and lints every template on every push

## Quick start

No Azure subscription needed to run the function code or validate the templates:

```bash
# Run the function app locally (needs Azure Functions Core Tools)
cp src/FunctionsDemo/local.settings.json.example src/FunctionsDemo/local.settings.json
func start --prefix src/FunctionsDemo
curl localhost:7071/api/health        # {"status":"ok"}
curl "localhost:7071/api/greet?name=Ada"  # {"greeting":"Hello, Ada!"}

# Run the tests
dotnet test

# Validate the Bicep (needs the Bicep CLI only — no Azure login)
bicep build infra/main.bicep
bicep lint infra/main.bicep
```

To deploy for real, you need the Azure CLI and a subscription:

```bash
az login
./scripts/whatif.sh my-resource-group dev   # preview, changes nothing
./scripts/deploy.sh my-resource-group dev   # create + deploy
```

Deploy prints the APIM gateway URL. Call the API through it, not through the function directly:

```bash
curl "https://<apim-name>.azure-api.net/greeting/greet?name=Ada" \
  -H "Ocp-Apim-Subscription-Key: <your-subscription-key>"
```

## How it works

```
callers ──► APIM (gateway, rate-limit policy) ──► Function App (.NET 8 isolated)
                │                                      │  system-assigned identity
                │                                      ▼
                │                                   Key Vault (RBAC: Secrets User)
                │
                └─ Storage account ──► Application Insights
```

| File | What it does |
|---|---|
| `infra/main.bicep` | Composes the modules, wires outputs together, grants the vault role |
| `infra/main.dev.bicepparam` | Dev parameters: APIM Consumption (pay-per-use, ~free at rest) |
| `infra/main.prod.bicepparam` | Prod parameters: APIM Developer (cheapest SKU with a portal) |
| `infra/modules/storage.bicep` | Storage account backing the Function App |
| `infra/modules/appInsights.bicep` | Log Analytics workspace + Application Insights |
| `infra/modules/keyVault.bicep` | Key Vault in RBAC mode (no access policies) |
| `infra/modules/keyVaultSecretsUser.bicep` | The one role assignment that grants secret access |
| `infra/modules/functionApp.bicep` | Linux Consumption plan + .NET 8 isolated Function App |
| `infra/modules/apim.bicep` | API Management service |
| `infra/modules/apimApi.bicep` | The API, its two operations, and the rate-limit/CORS policy |

Why the function is not the API's backend by direct URL: APIM's `serviceUrl` points at the function, so the function can stay locked down (no public traffic of its own) while APIM adds rate limiting, CORS, and a subscription key — the three things a bare function endpoint doesn't give you.

## Bicep vs Terraform, honestly

| | Bicep | Terraform |
|---|---|---|
| State | None — Azure tracks it | State file you must store and protect |
| Azure coverage | Day-one, first-party | Via the `azurerm` provider, usually close behind |
| Language | Azure-only DSL, compiles to ARM | Cross-cloud, its own HCL language |
| Modules | `.bicep` files, `module` blocks | Modules + registry, more mature ecosystem |
| When to pick it | Azure-only shops, ARM familiarity | Multi-cloud, or an existing Terraform estate |

The companion repo [`terraform-azure`](https://github.com/varunkonnojutech-lab/terraform-azure) builds the same shape of workload (App Service + SQL + Key Vault + Service Bus) in Terraform — read both and the trade-off stops being abstract.

## Cost

Consumption SKUs throughout in dev: Function Consumption (Y1) and APIM Consumption charge only for use, so the stack costs ~nothing sitting idle. Prod switches APIM to Developer (~$50/month at list price) for the portal and full features. Either way, delete the resource group when you're done experimenting — `az group delete --name <rg>`.

## Try it yourself

1. **Preview before you apply**: run `whatif.sh`, then add a tag in `main.bicep` and run it again — watch the diff show exactly one change.
2. **Break the build on purpose**: rename a module output in `main.bicep` without updating its consumer, push, and watch CI fail on `bicep build` before anything reaches Azure.
3. **Tighten the policy**: change the rate limit in `apimApi.bicep` from 100 to 5 calls/minute, deploy, and hammer the endpoint — the 429s are the lesson.
4. **Add a secret**: put a secret in the vault, give the function nothing new (it already has the role), and read it with the Azure SDK's `DefaultAzureCredential` — no config change, because identity is the credential.

## Next steps

- For the Terraform version of this workload, see [`terraform-azure`](https://github.com/varunkonnojutech-lab/terraform-azure).
- For the pipelines that would deploy this stack with approvals, see [`github-actions-patterns`](https://github.com/varunkonnojutech-lab/github-actions-patterns).
- For the Kubernetes half of the story, the next repo in this portfolio's queue is `aks-helm-deploy`.

## License

MIT — see [LICENSE](LICENSE).
