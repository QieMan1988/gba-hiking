param(
    [string]$TestType = "unit",
    [string]$GodotPath = "D:\Person\Godot\Godot_v4.6-stable_win64\Godot_v4.6-stable_win64.exe"
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$testDir = Join-Path $projectRoot "tests"
$resultsDir = Join-Path $testDir "results"

Write-Host "=================================================="
Write-Host "GBA Hiking Test Runner"
Write-Host "=================================================="
Write-Host "Test type: $TestType"
Write-Host "Project path: $projectRoot"
Write-Host "=================================================="

if (-not (Test-Path $GodotPath)) {
    Write-Host "[ERROR] Godot not found: $GodotPath"
    exit 1
}

if (-not (Test-Path $testDir)) {
    Write-Host "[WARN] Tests directory not found: $testDir"
    exit 0
}

New-Item -ItemType Directory -Path $resultsDir -Force | Out-Null
Get-ChildItem -Path $resultsDir -Filter "*.log" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

$testFiles = @()
switch ($TestType) {
    "unit" { $testFiles = Get-ChildItem -Path (Join-Path $testDir "unit") -Recurse -Filter "*_test.gd" -ErrorAction SilentlyContinue }
    "integration" { $testFiles = Get-ChildItem -Path (Join-Path $testDir "integration") -Recurse -Filter "*_integration_test.gd" -ErrorAction SilentlyContinue }
    "all" {
        $testFiles += Get-ChildItem -Path (Join-Path $testDir "unit") -Recurse -Filter "*_test.gd" -ErrorAction SilentlyContinue
        $testFiles += Get-ChildItem -Path (Join-Path $testDir "integration") -Recurse -Filter "*_integration_test.gd" -ErrorAction SilentlyContinue
    }
    default {
        Write-Host "[ERROR] Unknown test type: $TestType"
        Write-Host "[ERROR] Supported: unit, integration, all"
        exit 1
    }
}

if (-not $testFiles -or $testFiles.Count -eq 0) {
    Write-Host "[WARN] No test files found"
    exit 0
}

$total = 0
$passed = 0
$failed = 0

foreach ($testFile in $testFiles) {
    $total++
    $testName = $testFile.BaseName
    Write-Host "[TEST] Running: $testName"
    $logPath = Join-Path $resultsDir ("{0}.log" -f $testName)
    & $GodotPath --headless --script $testFile.FullName *> $logPath
    if ($LASTEXITCODE -eq 0) {
        $passed++
        Write-Host "[INFO] PASS: $testName"
    } else {
        $failed++
        Write-Host "[ERROR] FAIL: $testName"
        Write-Host "[ERROR] Log: $logPath"
    }
}

Write-Host ""
Write-Host "=================================================="
Write-Host "Test Summary"
Write-Host "=================================================="
Write-Host "Total: $total"
Write-Host "Passed: $passed"
Write-Host "Failed: $failed"

if ($total -gt 0) {
    $passRate = [int](($passed * 100) / $total)
    Write-Host "Pass rate: $passRate%"
    if ($passRate -ge 80) {
        Write-Host "Tests passed"
        exit 0
    } else {
        Write-Host "Tests failed (pass rate must be >= 80%)"
        exit 1
    }
}

exit 0
