# Demo 18 contributor rules

This is a self-contained teaching edition of the Entra/GitHub identity broker.
Read `README.md`, `BUILD-GUIDE.md` and `iteration/BUILD-RECORD.md` before changing
behavior or describing deployment status.

- Default to local work. Never run provisioning, consent, key-import, publishing,
  runtime-enable or cleanup scripts without separate explicit approval.
- Preserve admission/worker separation, real Entra JWT validation, live registry
  checks, durable acceptance and caller-isolated operation status.
- Keep GitHub tokens inside the worker. Do not add PATs, exported signing keys,
  broader workflow permissions, a credential vending API or authentication bypasses.
- Queues are at least once. Preserve expiry and conservative handling of
  ambiguous GitHub writes; never describe leases as exactly-once execution.
- Use synthetic examples only. Do not read or publish another clone's `.local`,
  `.azure`, private transcripts, customer drawings, identity mappings or secrets.
- Prompts are proposals, not authorisation. User consent, PIM, MFA, Azure RBAC and
  GitHub rules are enforced outside the model.
- Preserve test intent. Add regression coverage for changed behavior rather than
  replacing denied/failed outcomes with successful fallbacks.
- Run `.\go.ps1 -Verify -NoBrowser` for application changes and
  `.\tests\DemoRunner.Tests.ps1` for runner/documentation changes.
- Bicep changes additionally require compilation and the documented Checkov gate.
  Keep resource-scoped exceptions explicit; do not introduce a broad skip list.
- Keep local, hosted CI and live-service evidence separate. The inherited live
  setup is blocked at Entra admin grants; this clone has no deployment state.
