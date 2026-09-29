#requires -Version 7.4
[CmdletBinding()]
param(
    [switch]$Check,
    [switch]$Verify,
    [switch]$Manual,
    [switch]$NoBrowser,
    [switch]$Live
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
if (@(@($Check.IsPresent, $Verify.IsPresent, $Live.IsPresent) | Where-Object { $_ }).Count -gt 1) {
    throw 'Choose only one of -Check, -Verify or -Live.'
}
if ($Manual -and ($Check -or $Verify -or $Live)) { throw '-Manual is presenter pacing, not a verification or live-authoring flag.' }

$assets = @(
    'README.md', 'BUILD-GUIDE.md', 'RUN-SHEET.md', 'PROMPTS.md', 'WORKSHOP.md',
    'AGENTS.md', 'iteration\BUILD-RECORD.md', 'docs\architecture.md',
    'docs\runbook.md', 'docs\evidence.md', 'docs\infrastructure-checks.md',
    'EntraGitHubAgentIdentityDemo.slnx', 'global.json',
    'src\MaintenanceBroker\Program.cs', 'src\MaintenanceBroker\AzureStorage.cs',
    'src\MaintenanceBroker\Worker.cs', 'infra\main.bicep',
    'scripts\Test-Scripts.ps1', 'tools\DelegatedClient\DelegatedClient.csproj',
    'tests\DemoRunner.Tests.ps1'
)
foreach ($relative in $assets) {
    $path = Join-Path $root $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or (Get-Item -LiteralPath $path).Length -eq 0) {
        throw "Missing or empty demo asset: $relative"
    }
}
if ($Check) {
    Write-Host "Demo 18 assets: $($assets.Count) present. This does not run application tests or contact Azure/GitHub."
    return
}
if ($Verify) {
    if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) { throw '.NET SDK 10.0.401 or a compatible servicing patch is required.' }
    Push-Location $root
    try {
        & dotnet restore .\EntraGitHubAgentIdentityDemo.slnx --verbosity minimal
        if ($LASTEXITCODE -ne 0) { throw "Solution restore failed (exit $LASTEXITCODE)." }
        & dotnet build .\EntraGitHubAgentIdentityDemo.slnx -c Release --no-restore --verbosity minimal
        if ($LASTEXITCODE -ne 0) { throw "Broker build failed (exit $LASTEXITCODE)." }
        & dotnet test .\EntraGitHubAgentIdentityDemo.slnx -c Release --no-build --verbosity minimal
        if ($LASTEXITCODE -ne 0) { throw "Broker tests failed (exit $LASTEXITCODE)." }
        & dotnet build .\tools\DelegatedClient\DelegatedClient.csproj -c Release --verbosity minimal
        if ($LASTEXITCODE -ne 0) { throw "Delegated-client build failed (exit $LASTEXITCODE)." }
        & .\scripts\Test-Scripts.ps1
        & .\tests\DemoRunner.Tests.ps1
        Write-Host 'Application and offline script/runner gates passed. Bicep scanning and live identity proof are separate gates.'
    }
    finally { Pop-Location }
    return
}
if ($Live) {
    if (-not (Get-Command copilot -ErrorAction SilentlyContinue)) { throw 'Install/sign into Copilot CLI before selecting live authoring.' }
    Write-Host 'Starting real interactive Copilot authoring, not an Azure deployment or a recorded replay.'
    Write-Host 'Review your permission settings. The runner adds no allow-all flags; instructions are not a security sandbox.'
    $prompt = 'Read AGENTS.md, BUILD-GUIDE.md, PROMPTS.md and iteration/BUILD-RECORD.md. Explain this demo and propose one bounded local test-first improvement. Do not change files until I choose the improvement. Do not provision resources, grant permissions, sign in users, read private deployment state, publish or start a workflow.'
    Push-Location $root
    try {
        & copilot -i $prompt
        if ($LASTEXITCODE -ne 0) { throw "Interactive Copilot exited with code $LASTEXITCODE." }
    }
    finally { Pop-Location }
    return
}

Write-Host 'Demo 18 - Entra authorises the request; GitHub authorises the repository action.'
Write-Host 'Presentation only: no model execution, authentication, resource changes or generated PR.'
if (-not $NoBrowser) {
    Start-Process -FilePath (Join-Path $root 'BUILD-GUIDE.md') | Out-Null
}
$beats = @(
    @{ title = '1. WHY'; text = 'An agent needs a stable owner, bounded authority and revocation. A client ID is not a business policy. Millions of bank customers should not become millions of GitHub bots.' },
    @{ title = '2. TRUST BOUNDARIES'; text = 'CI OIDC or user sign-in -> Entra -> admission without signing rights -> private ledger/outbox/queue -> worker -> remote Key Vault signing -> GitHub App PR.' },
    @{ title = '3. HOW COPILOT HELPED'; text = 'Research current sources, implement a narrow baseline, expose restart/identity limitations, harden separate components, run negative tests, and preserve the actual admin denial.' },
    @{ title = '4. SHOW THE EVIDENCE'; text = 'Run go.ps1 -Verify -NoBrowser for fresh local checks. The original hosted build passed, but neither those tests nor this narration prove live Azure execution.' },
    @{ title = '5. THE HONEST STOP'; text = 'The original setup hit Entra 403 Authorization_RequestDenied. Azure Owner is not Entra directory admin. Follow the approved admin-grant runbook; never add a PAT fallback.' }
)
foreach ($beat in $beats) {
    Write-Host "`n$($beat.title)"
    Write-Host $beat.text
    if ($Manual) { Read-Host 'Press Enter to continue' | Out-Null }
}
Write-Host "`nNext: RUN-SHEET.md for presenting, WORKSHOP.md for the lab, PROMPTS.md for reusable authoring prompts."
