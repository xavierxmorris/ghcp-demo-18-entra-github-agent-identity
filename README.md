# Demo 18: build an Entra-GitHub agent identity broker with Copilot

A narrowly scoped operation broker demonstrating two distinct authorisation paths:
autonomous workload identity and delegated workforce-user identity. Entra
authorises a request; the broker applies a capability policy; a GitHub App
performs the approved repository action. This is not automatic identity mapping
between Entra and GitHub.

**Start with [why we chose this design and how we built it](BUILD-GUIDE.md).**
This self-contained teaching edition preserves the
[original public implementation](https://github.com/xavierxmorris/entra-github-agent-identity-demo)
and adds reusable prompts, presenter/workshop paths and a safe local runner.
It is part of the [GHCP demo suite](https://github.com/xavierxmorris/ghcp-demos).

| Track | Start here | Time after setup |
| --- | --- | --- |
| Understand why and reproduce the build | [Build guide](BUILD-GUIDE.md) | Read at your own pace |
| Present the design and evidence | [Run sheet](RUN-SHEET.md) | 5-7 minutes |
| Practice with Copilot and a bounded regression test | [Workshop](WORKSHOP.md) and [prompts](PROMPTS.md) | 60-90 minutes |
| Inspect the actual build history | [Sanitised build record](iteration/BUILD-RECORD.md) | Recorded evidence, not a live replay |

## Quick start: no cloud credentials needed

Use PowerShell 7.4+ for the runner and .NET SDK 10.0.401 or a compatible
servicing patch for the application checks.

```powershell
git clone https://github.com/xavierxmorris/ghcp-demo-18-entra-github-agent-identity.git
Set-Location .\ghcp-demo-18-entra-github-agent-identity
.\go.ps1 -Check
.\go.ps1 -NoBrowser
.\go.ps1 -Verify -NoBrowser
```

| Mode | Exact behavior |
| --- | --- |
| Default | Prints a five-beat walkthrough and opens the local build guide using its default application; no deployment, model run or PR |
| `-NoBrowser` | Suppresses opening the guide; combine with the default or `-Manual` presentation |
| `-Manual` | Pauses between presenter beats |
| `-Check` | Required nonempty-file preflight only; not application tests |
| `-Verify` | Restore/build/test broker, build delegated client, offline script and runner/docs contracts; package restore may need network |
| `-Live` | Starts interactive Copilot **authoring**, not Azure deployment, with an initial read-only planning prompt; no permission-bypass flags are added |

Choose only one of `-Check`, `-Verify` or `-Live`. `-Manual` is for presentation
only. Inspect your inherited Copilot permissions before live authoring; the
prompt and repository instructions are not a security sandbox.

## Current state

The durable broker, separate admission/worker modes, private-dependency Bicep,
bootstrap scripts and delegated client are implemented and locally verified.
**Azure deployment and live identity tests have not yet been completed.**
This is not a production deployment or a verified million-user implementation.
Live setup has reached a tenant-admin permission gate; paid compute remains
undeployed. See the [admin handoff](docs/runbook.md#if-tenant-permission-grants-are-denied).
That state belongs to the original isolated setup, not a deployment created by
cloning this repository. The clone contains no tenant state or credentials.

```mermaid
flowchart LR
    CI["Headless CI agent"] -->|"OIDC federation"| E["Entra"]
    U["Workforce user + agent"] -->|"Sign-in / consent"| E
    E -->|"API token"| A["Admission: no GitHub credentials"]
    A --> D["Private ledger + outbox + queue"]
    D --> W["Private worker"]
    W -->|"Managed identity; sign only"| K["Private Key Vault HSM key"]
    W -->|"Token stays in worker"| G["GitHub App: synthetic PR"]
    P["Current policy + revocation"] --> A
    P --> W
```

Bank customers belong on the customer application/authorisation plane, **not**
one GitHub account or App per customer. The delegated demonstration uses a
workforce test account; it is not customer identity provisioning.

- [Architecture, bank-scale boundaries and cost](docs/architecture.md)
- [Deployment and headless operation runbook](docs/runbook.md)
- [Infrastructure scan decisions](docs/infrastructure-checks.md)
- [Evidence and remaining live checks](docs/evidence.md)

## Local development

Prerequisites: .NET SDK 10.0.401 or a compatible servicing patch, PowerShell 7.4+,
Azure CLI with Bicep, and Checkov for the complete infrastructure gate.

```powershell
dotnet restore .\EntraGitHubAgentIdentityDemo.slnx
dotnet build .\EntraGitHubAgentIdentityDemo.slnx -c Release --no-restore
dotnet test .\EntraGitHubAgentIdentityDemo.slnx -c Release --no-build
dotnet build .\tools\DelegatedClient\DelegatedClient.csproj -c Release
.\scripts\Test-Scripts.ps1
az bicep build --file .\infra\main.bicep
```

`GET /healthz` is anonymous liveness. `/readyz` makes bounded, real storage
checks; App Service's authentication layer protects it in Azure.
`POST /v1/maintenance-pr` durably accepts the fixed capability and returns HTTP
202. `GET /v1/operations/{id}` is authenticated and caller-isolated.
The worker exposes health endpoints only and has public ingress disabled.

Both runtimes use explicit managed identities. There is deliberately no
developer-credential or in-memory production fallback. Tests use injected fakes
and real Azure-adapter contract checks without accessing cloud services.
Configuration is documented in `.env.example`; that file is not loaded
automatically. Actual deployment state stays in ignored `.local`.

## Honesty notes

- GitHub sees a GitHub App actor, not an Entra user or an individual agent run.
- The delegated path is a workforce-user test, not a bank customer identity
  implementation. Customer consent and customer data access need a separate
  authorisation boundary.
- The operation creates synthetic maintenance metadata and a PR. It is not an
  AI coding agent, a package updater or an autonomous merge mechanism.
- Durable state, ETags and a same-partition outbox support restart and duplicate
  delivery. GitHub cannot participate in that transaction: ambiguous work is
  quarantined or reconciled read-only, not blindly rerun.
- Runtime decisions expire within five minutes and never outlive the original
  Entra token. The demo permits one active operation and six starts/hour per
  GitHub installation; this is a safety budget, not a throughput benchmark.
- Existing Entra and GitHub tokens do not become instantly invalid when an
  identity is disabled. Update the live grant/control, stop workers and use
  GitHub-side suspension/revocation as appropriate.
- GitHub App approval/installation and user sign-in remain real consent steps.
  Normal autonomous runs are headless; MFA is never automated around.
- The imported key is HSM-protected **after** trusted import. GitHub generates
  the initial private key; it is never handed to an ordinary runner.
- B1 compute is not zone-redundant. There is no WAF, regional failover or
  million-user test. See the explicitly documented scan exceptions.
- No supplied customer diagrams, meeting transcript or internal roadmap
  material are included. This is an independently written generic example.
- The prompts are sanitised reusable reconstructions, not a private transcript.
  Local and hosted tests are distinct from the outstanding live identity proof.
