param(
  [switch]$UpdateScreenshots
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$artifactRoot = Join-Path $repoRoot "build\performance"
$logRoot = Join-Path $artifactRoot "logs"
New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$summaryLog = Join-Path $logRoot "suite-$timestamp.log"
$visualLog = Join-Path $logRoot "visual-$timestamp.log"
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

$suiteCommand = "flutter test test/performance/auth_gate_performance_test.dart test/performance/main_page_performance_test.dart"
$visualCommand = if ($UpdateScreenshots) {
  "flutter test --update-goldens test/performance/main_page_visual_smoke_test.dart"
} else {
  "flutter test test/performance/main_page_visual_smoke_test.dart"
}

Invoke-And-Capture -Command $suiteCommand -LogPath $summaryLog
Invoke-And-Capture -Command $visualCommand -LogPath $visualLog

$perfLines = @()
$perfLines += Select-String -Path $summaryLog -Pattern "\[perf\]" | ForEach-Object { $_.Line.Trim() }

$screenshots = @(
  "test/performance/goldens/main_page_trainee_shell.png",
  "test/performance/goldens/main_page_trainee_menu_open.png",
  "test/performance/goldens/main_page_trainer_shell.png",
  "test/performance/goldens/main_page_trainer_menu_open.png"
)

$report = @()
$report += "# Performance Suite Report"
$report += ""
$report += "- Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
$report += "- Workspace: ``$repoRoot``"
$report += "- Screenshot mode: " + ($(if ($UpdateScreenshots) { "Updated goldens" } else { "Validated existing goldens" }))
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
$report += "## Screenshots"
$report += ""
foreach ($shot in $screenshots) {
  if (Test-Path (Join-Path $repoRoot $shot)) {
    $fullPath = "/" + ((Join-Path $repoRoot $shot).Replace('\', '/'))
    $report += "### $(Split-Path $shot -Leaf)"
    $report += ""
    $report += "![${shot}]($fullPath)"
    $report += ""
  }
}
$report += "## Logs"
$report += ""
$report += "- Suite log: ``$summaryLog``"
$report += "- Visual log: ``$visualLog``"

Set-Content -Path $reportPath -Value $report -Encoding UTF8

Write-Host ""
Write-Host "Performance report written to:" -ForegroundColor Green
Write-Host $reportPath -ForegroundColor Green
