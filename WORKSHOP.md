# Demo 18 workshop: build the authority boundary, then test it

**Time:** 60-90 minutes after local setup. Tenant approval, downloads and cloud
provisioning are additional. **Deliverable:** a design rationale, fresh local
evidence, one bounded regression test and an honest live-readiness handoff.

## Start safely

Use your own disposable clone. Install .NET 10 and PowerShell 7.4+; use Copilot
only when authorised. No Azure subscription or GitHub App is needed for the
local exercise. Do not copy `.local` state from another user or environment.

```powershell
.\go.ps1 -Check
.\go.ps1 -Verify -NoBrowser
```

Record your commit and outputs. Distinguish the two commands: the first checks
assets, while the second builds and runs actual tests.

## Lab

| Time | Activity | Acceptance evidence |
| --- | --- | --- |
| 0-15 min | Read the why/decision table and draw the trust boundaries without looking at the diagram | Explain which component has an Entra token, a GitHub token, signing rights and policy-write rights |
| 15-30 min | Follow the caller classification and fixed request shape | Explain why a supplied user ID, app role on a delegated token or different repository cannot authorise a request |
| 30-45 min | Inspect outbox and worker tests | Predict the outcome of persist-before-send, send-before-mark and competing acquisition; cite an existing assertion |
| 45-65 min | Ask Copilot for one additional local negative/boundary test, then review and execute it | Test exercises a real contract, fails if that contract is weakened, and passes without relaxing production checks |
| 65-80 min | Explain the Entra 403 and prepare a least-privilege admin request in prose | Azure Owner vs Entra roles vs Graph permissions are distinct; no secret/PAT fallback |
| 80-90 min | Write the handoff | Files changed, commands/results, current status, live prerequisites and limits |

For a 60-minute slot, discuss the admin handoff and final rubric rather than
running any live configuration.

## Suggested bounded prompt

```text
Read AGENTS.md and the existing worker, policy and HTTP tests.
Propose one missing negative test concerning caller isolation or queued revocation.
State which existing contract it protects and which incorrect implementation
would make it fail. Wait for my choice before editing.
Do not change production permissions, call cloud APIs or rewrite existing tests.
```

Once you approve the test, let Copilot implement it and run the smallest relevant
test selection, followed by the broader local gate. A passing assertion that
would also pass with the policy removed is not useful evidence.

## Prediction matrix

| Situation | Required explanation |
| --- | --- |
| Same request ID and same caller, duplicated queue delivery | Same durable operation; conditional ownership prevents two normal acquisitions |
| Same request ID under a different caller | Different identity-bound key; no access to another caller's status |
| Grant disabled after admission | Worker rechecks current policy; old queued authority must not continue |
| Delegated decision waits past its allowed lifetime | User authority is not extended by queue retention |
| GitHub request may have succeeded before the worker crashed | Read-only deterministic reconciliation or visible ambiguity, never exactly-once claims |
| Storage cannot persist a terminal/poison outcome | No successful acknowledgement that loses the failure record |
| User has Azure Owner but not the required Entra permission | Stop at the grant boundary and use the authorised admin path |

## Optional live extension

Only after separate approval, follow [the runbook](docs/runbook.md). Use new
isolated names and a disposable repository. Budget roughly USD 60/month at
low usage, not a cap. Prefer private administrative connectivity; a selected-IP
bootstrap exception needs explicit approval and verified cleanup.

Demonstrate both identity paths and at least one real denial only when the
tenant grants, App installation and private infrastructure exist. A successful
local workshop does not satisfy that live acceptance criterion.

## Rubric and non-goals

- **Understand:** correctly explain both authorisation decisions and the customer/engineering split.
- **Apply:** add a bounded meaningful test and reproduce its evidence.
- **Evaluate:** identify residual token lifetime, admission trust, ambiguous writes and deployment limitations.
- **Operate:** name the required approver and recovery path without bypassing controls.

This is not customer banking integration, an AI code-generation service, a
million-user benchmark, a regulatory certification or an automatic merge bot.
