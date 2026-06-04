param(
    [int]$Trials = 1,
    [string]$Project = $(if ($env:COMPOSE_PROJECT_NAME) { $env:COMPOSE_PROJECT_NAME } else { "attack_me_1" }),
    [string]$ClaudeConfigDir = (Join-Path $HOME ".claude"),
    [string]$Model = $env:CLAUDE_MODEL,
    [int]$TimeoutSeconds = $(if ($env:TIMEOUT_S) { [int]$env:TIMEOUT_S } else { 3600 }),
    [int]$MaxTurns = $(if ($env:MAX_TURNS) { [int]$env:MAX_TURNS } else { 0 }),
    [switch]$KeepEnvironmentUp
)

$ErrorActionPreference = "Stop"

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootCompose = Join-Path (Resolve-Path (Join-Path $here "..\experiment_app")).Path "docker-compose.yml"
$attackerCompose = Join-Path $here "docker-compose.attacker.yml"

if (-not (Test-Path $rootCompose)) {
    throw "Could not find root docker-compose.yml at $rootCompose"
}

$hasApiKey = -not [string]::IsNullOrWhiteSpace($env:ANTHROPIC_API_KEY)
$hasClaudeDir = Test-Path $ClaudeConfigDir
if (-not $hasApiKey -and -not $hasClaudeDir) {
    throw "No Claude auth available. Set ANTHROPIC_API_KEY or provide a Claude config dir."
}

function Invoke-Compose {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
    & docker compose -p $Project -f $rootCompose -f $attackerCompose @Args
    if ($LASTEXITCODE -ne 0) {
        throw "docker compose failed with exit code $LASTEXITCODE"
    }
}

function New-RunId {
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
    $suffix = -join ((1..8) | ForEach-Object { '{0:x}' -f (Get-Random -Minimum 0 -Maximum 16) })
    "$timestamp-$suffix"
}

function Start-ServiceLogCapture {
    param(
        [string]$StdoutLogPath,
        [string]$StderrLogPath
    )

    $argList = @(
        "compose", "-p", $Project,
        "-f", $rootCompose,
        "-f", $attackerCompose,
        "logs", "-f", "--no-color", "web", "backend", "sql"
    )

    Start-Process `
        -FilePath "docker" `
        -ArgumentList $argList `
        -NoNewWindow `
        -RedirectStandardOutput $StdoutLogPath `
        -RedirectStandardError $StderrLogPath `
        -PassThru
}

try {
    New-Item -ItemType Directory -Force -Path (Join-Path $here "runs") | Out-Null

    for ($i = 1; $i -le $Trials; $i++) {
        $runId = New-RunId
        $runDir = Join-Path $here "runs\$runId"
        $servicesLog = Join-Path $runDir "services.log"
        $servicesErrLog = Join-Path $runDir "services.stderr.log"
        New-Item -ItemType Directory -Force -Path $runDir | Out-Null

        Write-Host "=============================================================="
        Write-Host "[run.ps1] Trial $i/$Trials - reprovisioning testbed"
        Write-Host "=============================================================="

        try {
            Invoke-Compose down -v --remove-orphans
        } catch {
            Write-Host "[run.ps1] Ignoring compose down failure during cleanup."
        }

        Invoke-Compose up --build -d web backend sql

        Write-Host "[run.ps1] Waiting for web ingress to come up..."
        Start-Sleep -Seconds 5

        Write-Host "[run.ps1] Capturing web/backend/sql logs to $servicesLog"
        $logProcess = Start-ServiceLogCapture -StdoutLogPath $servicesLog -StderrLogPath $servicesErrLog

        try {
            $runArgs = @(
                "compose", "-p", $Project,
                "-f", $rootCompose,
                "-f", $attackerCompose,
                "run", "--rm", "--build",
                "-e", "RUN_ID=$runId"
            )

            if (-not [string]::IsNullOrWhiteSpace($Model)) {
                $runArgs += @("-e", "CLAUDE_MODEL=$Model")
            }

            if ($TimeoutSeconds -gt 0) {
                $runArgs += @("-e", "TIMEOUT_S=$TimeoutSeconds")
            }

            if ($MaxTurns -gt 0) {
                $runArgs += @("-e", "MAX_TURNS=$MaxTurns")
            }

            if ($hasClaudeDir) {
                $runArgs += @("-v", "${ClaudeConfigDir}:/home/attacker/.claude")
            }

            Write-Host "[run.ps1] Launching black-box attacker (foreground)..."
            & docker @runArgs attacker
            $rc = $LASTEXITCODE
        } finally {
            if ($logProcess -and -not $logProcess.HasExited) {
                Stop-Process -Id $logProcess.Id -Force
            }
        }

        Write-Host "[run.ps1] Attacker exited rc=$rc (0 = FLAG captured)."
        $summaryPath = Join-Path $runDir "summary.json"
        if (Test-Path $summaryPath) {
            Write-Host "[run.ps1] Summary for trial ${i}:"
            Get-Content -Raw $summaryPath
            Write-Host ""
            Write-Host "[run.ps1] Trace dir: $runDir"
            Write-Host "[run.ps1]   decisions -> $(Join-Path $runDir 'decisions.jsonl')"
            Write-Host "[run.ps1]   commands  -> $(Join-Path $runDir 'commands.jsonl')"
            Write-Host "[run.ps1]   timeline  -> $(Join-Path $runDir 'events.jsonl')"
            Write-Host "[run.ps1]   services  -> $servicesLog"
            if (Test-Path $servicesErrLog) {
                Write-Host "[run.ps1]   services stderr -> $servicesErrLog"
            }
        }
    }
} finally {
    if (-not $KeepEnvironmentUp) {
        Write-Host "[run.ps1] Tearing down testbed..."
        try {
            Invoke-Compose down -v --remove-orphans
        } catch {
            Write-Host "[run.ps1] compose down returned a non-zero exit code during final cleanup."
        }
    }
}
