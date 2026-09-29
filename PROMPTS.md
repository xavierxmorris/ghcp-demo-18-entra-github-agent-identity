# Reusable Copilot prompts for demo 18

These are **sanitised, reusable reconstructions** of the engineering tasks,
not the original conversation, private meeting text or a guarantee of identical
generated code. Run them sequentially; review each result before expanding scope.
Use `BUILD-GUIDE.md` for the original sequence and `AGENTS.md` for boundaries.

## 1. Research and decide, without touching the cloud

```text
Design a demonstration of Entra-authorised agent operations in GitHub.
Support a federated CI workload and a separately authorised workforce-user
delegated client. Only create synthetic maintenance metadata and a pull request
in one disposable repository. Never merge or expose GitHub credentials to the caller.

Use current Microsoft Learn and GitHub sources. Distinguish Entra authentication,
broker capability authorisation, GitHub App permissions and repository rules.
Explain why millions of customers do not imply millions of GitHub accounts.

Return a simple diagram, decision table, acceptance cases, cost assumptions and
unresolved prerequisites. Label future ideas and unverified claims explicitly.
Do not create resources, registrations, grants, keys, repositories or credentials.
```

Accept when the design separates both identity planes and identifies the
Entra-admin, App-installation, user-consent and private-bootstrap gates.

## 2. Implement the local baseline

```text
Read the approved design and repository instructions. Implement a .NET 10
operation broker for the fixed sandbox-maintenance capability.
Validate single-tenant Entra v2 JWT issuer, audience, signature and expiry.
Workloads need Maintenance.Request without delegated scopes. Delegated requests
need Agent.Invoke plus the authenticated user and client binding.

Accept only capabilityId and a canonical request GUID. Never accept repository,
path, arbitrary code or a claimed identity from the request. Use managed identity
and a version-pinned Key Vault RS256 signer. Keep the scoped GitHub installation
token inside the operation and attempt revocation on success, failure and cancellation.

Add positive and negative tests. Run restore, Release build and targeted tests;
fix real failures without weakening assertions. Do not deploy, sign in or call live APIs.
Report implemented behavior, commands/results and remaining limitations.
```

Accept only with evidence for role/scope confusion, unexpected fields, wrong
caller and repository binding. A happy-path-only PR test is insufficient.

## 3. Remove the prototype's durability and privilege coupling

```text
Harden the existing broker into Admission and Worker modes with separate
managed identities. Admission must not construct a signer or GitHub executor.
Replace memory state with Azure Table operations plus same-partition outbox
transactions and Azure Queue delivery. Do not add an in-memory production fallback.

Define a point-read policy/grant schema shared with the bootstrap scripts.
Use ETags for ownership, caller-isolated status, bounded decision expiry,
persistent per-installation budgets, explicit poison/failure states and read-only
reconciliation for stale work. Never claim exactly-once across Azure and GitHub.

Cover persist-before-send, send-before-mark, duplicate delivery, competing workers,
restart, queued revocation, delegated expiry and dependency errors. Preserve the
fixed synthetic PR operation. Run tests and report the exact deployment contract.
Do not edit infrastructure or make live changes.
```

For substantial parallel work, assign disjoint file ownership and agree the
configuration/entity schema before integrating. Do not create multiple agents
merely to repeat the same searches.

## 4. Generate infrastructure and administrator automation

```text
Using the approved application contract, generate Bicep and PowerShell scripts
for two separate Linux App Service plans/identities, private table/queue/vault
endpoints and DNS, scoped RBAC, diagnostics and exact CI federation.
Disable shared storage keys and public worker/data ingress. Admission is the
explicit authenticated public exception. Runtime policy access is read-only.

Script separate Entra app-role and user-delegated grants, a protected GitHub
sandbox, supported GitHub App manifest approval, trusted HSM key import, registry
seeding, immutable-package deployment, kill switches and cleanup.
Do not invent a fully headless administrator consent or MFA bypass.

Compile Bicep and run the infrastructure scan. Explain every resource exception;
never suppress all findings. Document cost, prerequisites and remaining gaps.
Generate files only. Wait for separate explicit approval before live changes.
```

Accept when script parameters, environment settings, identity scopes and table
types match the application exactly, not just when the template compiles.

## 5. Investigate a real refusal

```text
The custom API permission assignment returned HTTP 403 Authorization_RequestDenied.
Distinguish Azure resource ownership from Entra directory roles and API permissions.
Inspect only the relevant authorised state and the failing operation.

Preserve fail-closed behavior. Do not use a PAT, broaden runtime Graph permissions,
disable assignment requirements, impersonate a user or automate around PIM/MFA.
Prepare the smallest administrator handoff and record what was and was not created.
Stop paid deployment until required grants can be verified.
```

Accept a precise blocked outcome. A model-generated workaround that bypasses
the chosen authority is not a successful demo.

## 6. Verify and publish only what the evidence supports

```text
Run the local gates and inspect the files that will be published.
Exclude private state, tenant mappings, secrets, customer diagrams and transcripts.
Record the revision, versions, exact results and unverified live checks.
Explain how to repeat the build, why the design was chosen and the production limits.

With separate publication approval, push the sanitised source, verify hosted CI
and record the resulting URLs. Do not report a local test as proof of live Entra,
Key Vault or GitHub enforcement. Keep the original source repository unchanged
when creating a derived teaching edition.
```

## Prompt evaluation

For each run, record the prompt version, repository revision, selected model,
expected behavior, actual command/result and residual uncertainty. A different
model or run may generate different code. Score compliance against tests and
requirements, not prose confidence. Never publish raw private session logs.
