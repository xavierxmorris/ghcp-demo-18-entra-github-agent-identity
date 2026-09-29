# Demo 18 presenter run sheet

**Audience:** platform engineers, identity/security architects and developers.
**Duration:** 5-7 minutes after setup; live cloud provisioning is not part of
this slot. A local verification run may take longer on a cold dependency cache.

Before presenting:

```powershell
.\go.ps1 -Check
.\go.ps1 -Verify -NoBrowser
.\go.ps1 -Manual -NoBrowser
```

The last command is a guided explanation, not generated execution evidence.
Keep [BUILD-GUIDE.md](BUILD-GUIDE.md), [the diagram](docs/architecture.md) and
[the evidence boundary](iteration/BUILD-RECORD.md) visible.

| Beat | What to show | What to say |
| --- | --- | --- |
| 0:00-1:00: why | Design decision table | "We need permission to request an operation and permission to act in a repository. Those are not the same identity decision." |
| 1:00-2:00: boundaries | Diagram | "The runner gets an Entra API token. Only the private worker obtains the GitHub App token. The private key never goes to an ordinary job." |
| 2:00-3:00: build method | Staged build table and prompts | "Copilot helped build a narrow baseline, then harden its identified weaknesses. It did not grant itself authority." |
| 3:00-4:30: prove a negative | Tests for caller isolation, queued revocation or duplicate acquisition | "The important result is not just a successful PR. Wrong authority must fail, and a retry must not become a second arbitrary write." |
| 4:30-5:30: honest stop | Recorded Entra 403 and admin handoff | "Azure Owner is not tenant application administration. The refusal is real. We kept the boundary instead of adding a PAT." |
| 5:30-7:00: scaling | Customer/engineering split and residual risks | "Millions of customers do not mean millions of GitHub actors. This small demo proves neither production availability nor that throughput." |

## Questions worth answering explicitly

**Is this a native GitHub agent identity?** No. It is an operation broker built
from Entra identities, managed identity, Key Vault and a GitHub App.

**Does Entra disable instantly revoke GitHub access?** No. Existing tokens and
in-flight requests have residual lifetime. Registry revocation, bounded authority,
token cleanup and GitHub-side suspension all have distinct effects.

**Why not use only GITHUB_TOKEN?** That can be the right simpler solution when
Entra need not be the mandatory gate for obtaining GitHub write access.

**Is it fully headless?** Ordinary workload runs can be. Administrator App
approval and the delegated user's authentication/consent cannot be bypassed.

**Where is the live PR?** Live end-to-end proof is pending the original tenant's
admin grant. Show the exact state; never substitute a locally mocked test as a
real PR created by this deployment.

**Which model made this correct?** The model assisted implementation. Concrete
requirements, source verification, tests and service responses are the evidence.

## Safe fallback

If toolchains or cloud access are unavailable, use the diagram, checked-in
source and original hosted CI links. Call it a walkthrough of recorded evidence,
not a fresh run. Never trigger provisioning to save a presentation.
