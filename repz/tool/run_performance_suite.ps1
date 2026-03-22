$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$artifactRoot = Join-Path $repoRoot "build\performance"
$logRoot = Join-Path $artifactRoot "logs"
New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$summaryLog = Join-Path $logRoot "suite-$timestamp.log"
$reportPath = Join-Path $artifactRoot "performance-report-$timestamp.md"

function Invoke-And-Capture {
  param(
    [string]$Command,
    [string]$LogPath
  )

  Write-Host ""
  Write-Host "Running: $Command" -ForegroundColor Cyan
  & powershell -NoProfile -Command $Command 2>&1 | Tee-Object -FilePath $LogPath
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed: $Command"
  }
}

$suiteCommand = "flutter test test/performance/auth_gate_performance_test.dart test/performance/entry_flow_performance_test.dart test/performance/main_page_performance_test.dart"

Invoke-And-Capture -Command $suiteCommand -LogPath $summaryLog

$perfLines = @()
$perfLines += Select-String -Path $summaryLog -Pattern "\[perf\]" | ForEach-Object { $_.Line.Trim() }

$report = @()
$report += "# Performance Suite Report"
$report += ""
$report += "- Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
$report += "- Workspace: ``$repoRoot``"
$report += "- Scope: auth, entry, and role-aware shell performance smoke"
$report += ""
$report += "## Timings"
$report += ""
if ($perfLines.Count -eq 0) {
  $report += "No `[perf]` timing lines were captured."
} else {
  foreach ($line in $perfLines) {
    $report += "- ``$line``"
  }
}
$report += ""
$report += "## Logs"
$report += ""
$report += "- Suite log: ``$summaryLog``"

Set-Content -Path $reportPath -Value $report -Encoding UTF8

Write-Host ""
Write-Host "Performance report written to:" -ForegroundColor Green
Write-Host $reportPath -ForegroundColor Green
