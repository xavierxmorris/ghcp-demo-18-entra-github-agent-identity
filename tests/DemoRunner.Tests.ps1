#requires -Version 7.4
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$script:checks = 0
function Assert-Check([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "FAILED: $Message" }
    $script:checks++
}
function Assert-Rejected([scriptblock]$Action, [string]$Expected) {
    $failure = $null
    try { & $Action 6>&1 | Out-Null }
    catch { $failure = $_ }
    Assert-Check ($null -ne $failure -and $failure.Exception.Message.Contains($Expected)) "Reject: $Expected"
}

$tokens = $null
$parseErrors = $null
$runner = [Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $root 'go.ps1'), [ref]$tokens, [ref]$parseErrors)
Assert-Check ($parseErrors.Count -eq 0) 'Runner parses'
$assetAssignment = $runner.Find({
    param($node)
    $node -is [Management.Automation.Language.AssignmentStatementAst] -and
        $node.Left -is [Management.Automation.Language.VariableExpressionAst] -and
        $node.Left.VariablePath.UserPath -eq 'assets'
}, $true)
Assert-Check ($null -ne $assetAssignment) 'Runner declares a literal asset list'
$assetArray = $assetAssignment.Right.Find({
    param($node)
    $node -is [Management.Automation.Language.ArrayLiteralAst]
}, $true)
Assert-Check ($null -ne $assetArray) 'Asset list is a literal array'
$assets = @($assetArray.Elements | ForEach-Object {
    Assert-Check ($_ -is [Management.Automation.Language.StringConstantExpressionAst]) 'Asset path is a literal string'
    $_.Value
})
foreach ($asset in $assets) {
    $path = Join-Path $root $asset
    Assert-Check ((Test-Path -LiteralPath $path -PathType Leaf) -and (Get-Item -LiteralPath $path).Length -gt 0) "Asset: $asset"
}

$documents = @(
    Get-ChildItem -LiteralPath $root -File -Filter '*.md'
    Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter '*.md'
    Get-ChildItem -LiteralPath (Join-Path $root 'iteration') -File -Filter '*.md'
)
foreach ($document in $documents) {
    $text = Get-Content -LiteralPath $document.FullName -Raw
    foreach ($match in [regex]::Matches($text, '\[[^\]\r\n]+\]\(([^)\s]+)\)')) {
        $target = $match.Groups[1].Value
        if ($target -match '^(?:[a-z]+:|#)') { continue }
        $relative = [Uri]::UnescapeDataString(($target -split '#', 2)[0])
        $path = Join-Path $document.DirectoryName $relative
        Assert-Check (Test-Path -LiteralPath $path) "$($document.Name) local link: $target"
    }
}

$mockState = [pscustomobject]@{
    DotnetCalls = [Collections.Generic.List[string]]::new()
    DotnetFailureAt = 0
    CopilotCalls = [Collections.Generic.List[object]]::new()
    CopilotExit = 0
    Opened = [Collections.Generic.List[string]]::new()
    Pauses = 0
    MissingCommand = ''
}
function Get-Command {
    [CmdletBinding()]
    param([string]$Name)
    if ($Name -cne $mockState.MissingCommand) {
        Microsoft.PowerShell.Core\Get-Command $Name -ErrorAction Stop
    }
}
function dotnet {
    $mockState.DotnetCalls.Add(($args -join ' '))
    $global:LASTEXITCODE = if ($mockState.DotnetFailureAt -eq $mockState.DotnetCalls.Count) { 23 } else { 0 }
}
function copilot {
    $mockState.CopilotCalls.Add(@{ arguments = @($args); directory = (Get-Location).Path })
    $global:LASTEXITCODE = $mockState.CopilotExit
}
function Start-Process { param($FilePath); $mockState.Opened.Add($FilePath) }
function Read-Host { param($Prompt); $mockState.Pauses++; return '' }
function az { throw 'Cloud command called from offline runner tests.' }
function gh { throw 'GitHub command called from offline runner tests.' }

$fixture = Join-Path $root ('.local\runner-tests-' + [Guid]::NewGuid().ToString('N'))
$previousExit = if (Test-Path Variable:\global:LASTEXITCODE) { $global:LASTEXITCODE } else { 0 }
New-Item -ItemType Directory -Path $fixture -Force | Out-Null
try {
    foreach ($asset in $assets) {
        $path = Join-Path $fixture $asset
        New-Item -ItemType Directory -Path (Split-Path $path -Parent) -Force | Out-Null
        Set-Content -LiteralPath $path -Value '# Synthetic runner fixture' -Encoding utf8
    }
    $entry = Join-Path $fixture 'go.ps1'
    Copy-Item -LiteralPath (Join-Path $root 'go.ps1') -Destination $entry

    & $entry -Check 6>&1 | Out-Null
    & $entry -NoBrowser 6>&1 | Out-Null
    Assert-Check ($mockState.DotnetCalls.Count -eq 0 -and $mockState.CopilotCalls.Count -eq 0 -and $mockState.Opened.Count -eq 0) 'Check/walkthrough stay offline and NoBrowser suppresses opening'
    & $entry -Manual 6>&1 | Out-Null
    Assert-Check ($mockState.Pauses -eq 5 -and $mockState.Opened.Count -eq 1) 'Manual mode pauses once per beat and opens the guide'
    Assert-Check ($mockState.Opened[0] -eq (Join-Path $fixture 'BUILD-GUIDE.md')) 'Only the local build guide is opened'
    Assert-Rejected { & $entry -Check -Verify } 'Choose only one'
    Assert-Rejected { & $entry -Check -Live } 'Choose only one'
    Assert-Rejected { & $entry -Verify -Live } 'Choose only one'
    foreach ($mode in @('Check', 'Verify', 'Live')) {
        $selection = @{ $mode = $true; Manual = $true }
        Assert-Rejected { & $entry @selection } '-Manual is presenter pacing'
    }
    $mockState.MissingCommand = 'dotnet'
    Assert-Rejected { & $entry -Verify } '.NET SDK'
    $mockState.MissingCommand = 'copilot'
    Assert-Rejected { & $entry -Live } 'Install/sign into Copilot CLI'
    $mockState.MissingCommand = ''

    $initialLocation = (Get-Location).Path
    & $entry -Verify -NoBrowser 6>&1 | Out-Null
    Assert-Check ($mockState.DotnetCalls.Count -eq 4) 'Verify runs all four dotnet commands'
    Assert-Check ($mockState.DotnetCalls[0].StartsWith('restore ') -and
        $mockState.DotnetCalls[1].StartsWith('build ') -and $mockState.DotnetCalls[1].Contains('--no-restore') -and
        $mockState.DotnetCalls[2].StartsWith('test ') -and $mockState.DotnetCalls[2].Contains('--no-build') -and
        $mockState.DotnetCalls[3].Contains('DelegatedClient.csproj')) 'Verify preserves command order and target contracts'
    Assert-Check ((Get-Location).Path -eq $initialLocation) 'Verify restores caller location'
    foreach ($stage in 1..4) {
        $mockState.DotnetCalls.Clear()
        $mockState.DotnetFailureAt = $stage
        Assert-Rejected { & $entry -Verify } 'exit 23'
        Assert-Check ($mockState.DotnetCalls.Count -eq $stage) "Verify stops at failed stage $stage"
        Assert-Check ((Get-Location).Path -eq $initialLocation) 'Failure restores caller location'
    }
    $mockState.DotnetFailureAt = 0
    foreach ($contract in @('scripts\Test-Scripts.ps1', 'tests\DemoRunner.Tests.ps1')) {
        $contractPath = Join-Path $fixture $contract
        Set-Content -LiteralPath $contractPath -Value "throw 'Synthetic contract failure'"
        Assert-Rejected { & $entry -Verify } 'Synthetic contract failure'
        Set-Content -LiteralPath $contractPath -Value '# Synthetic runner fixture'
    }

    & $entry -Live 6>&1 | Out-Null
    Assert-Check ($mockState.CopilotCalls.Count -eq 1 -and $mockState.CopilotCalls[0].directory -eq $fixture) 'Live authoring starts in the chosen clone'
    $cliArguments = $mockState.CopilotCalls[0].arguments
    Assert-Check ($cliArguments.Count -eq 2 -and $cliArguments[0] -ceq '-i') 'Interactive prompt only; no allow-all flags or model override'
    Assert-Check ($cliArguments[1].Contains('Do not change files until I choose') -and
        $cliArguments[1].Contains('Do not provision')) 'Initial prompt requests planning, not deployment'
    $mockState.CopilotExit = 29
    Assert-Rejected { & $entry -Live } 'code 29'
    Assert-Check ((Get-Location).Path -eq $initialLocation) 'Live failure restores caller location'

    $readme = Join-Path $fixture 'README.md'
    Set-Content -LiteralPath $readme -Value '' -NoNewline
    Assert-Rejected { & $entry -Check } 'Missing or empty demo asset: README.md'
    Remove-Item -LiteralPath $readme
    Assert-Rejected { & $entry -Check } 'Missing or empty demo asset: README.md'
}
finally {
    $global:LASTEXITCODE = $previousExit
    Remove-Item -LiteralPath $fixture -Recurse -Force
}
Write-Host "$script:checks runner/documentation checks passed. Tool execution in runner fixtures was mocked; application tests are separate."
