# Sanitised build record

Recorded: **2026-09-29**. This is a curated engineering record, not a raw session
transcript. Private conversations, source drawings and tenant identifiers are
intentionally absent.

## Provenance

- Original public source:
  <https://github.com/xavierxmorris/entra-github-agent-identity-demo>
- Teaching-edition source baseline:
  `e4ca200760769a2e6a4bf9fc7eea3e606be96c88`.
- Core implementation commit:
  `4f74a5f05666cebfdbd26e17e41756e785003d73`.
- [Original hosted CI](https://github.com/xavierxmorris/entra-github-agent-identity-demo/actions/runs/36548338888).
- [Original immutable release](https://github.com/xavierxmorris/entra-github-agent-identity-demo/releases/tag/demo-4f74a5f05666).

The numbered edition preserves original commit history and changes the teaching
material/runner, not the broker's authority model. Original tenant deployment
state is excluded. Its CI and release links remain **original-repository
evidence**, not evidence of a deployed service in this clone.

## Recorded original results

| Gate | Observed result |
| --- | --- |
| Initial broker baseline | 98 tests passed |
| Hardened broker Release build | Zero warnings/errors |
| Hardened broker tests | 177 passed; zero failed/skipped |
| Delegated client Release build | Zero warnings/errors |
| Offline provisioning/script contracts | 60 passed |
| Bicep compilation | Exit 0 |
| Checkov 3.3.19, Bicep source | 37 passed, 0 failed, 21 documented resource exceptions |
| Hosted CI on the implementation commit | Passed |
| Entra live role assignment | HTTP 403 `Authorization_RequestDenied` |
| Live GitHub App/HSM/broker execution | Not completed |

The temporary first Graph query failure (`400 Request_UnsupportedQuery`) was
fixed without changing the required authorisation. The subsequent 403 remained
an actual administrator requirement.

## Reproduce rather than borrow the result

```powershell
.\go.ps1 -Verify -NoBrowser
az bicep build --file .\infra\main.bicep
checkov -d .\infra --framework bicep --quiet
```

Record fresh counts and the current commit if you change tests or dependencies.
Use this edition's [Actions runs](https://github.com/xavierxmorris/ghcp-demo-18-entra-github-agent-identity/actions)
for its own hosted gate. Do not publish local tenant state or raw authentication
logs as workshop evidence.

## Fresh teaching-edition checks

Before the initial publication, this clone ran `.\go.ps1 -Verify -NoBrowser`:
177 broker tests and 60 provisioning contracts passed; broker/client builds
had zero warnings/errors. Runner/documentation tests covered file presence,
local link targets, flag conflicts, missing tools, native-command failures,
contract-script failures, location restoration and the interactive CLI arguments.
Those runner tests mock external tools; the broker tests above are a separate
real test run. `az bicep build --file .\infra\main.bicep` also exited zero.

Packaging exposed two test-harness issues before publication: `SafeGetValue`
could not evaluate the complete asset-array statement, and script-scoped mock
state was not visible when invoked from the child runner. The tests now inspect
literal AST elements and share an explicit mock-state object. Neither fix
changed the broker or its identity controls.

The suite index separately passed its inventory validation and 13 publisher/
index unit tests. Hosted checks for this edition are linked above; live Entra,
vault and GitHub execution remain pending, not inferred from local results.

## What was not measured

No elapsed AI-generation benchmark, model comparison, productivity percentage,
independent dual-model audit, million-user load test, regional failover test or
production compliance assessment was performed. Prompt reconstructions are
not evidence that another model run will produce identical code.
