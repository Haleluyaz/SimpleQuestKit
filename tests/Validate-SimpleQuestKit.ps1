Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$SrcRoot = Join-Path $RepoRoot "src"
$Failures = New-Object System.Collections.Generic.List[string]

function Add-Failure {
    param([string] $Message)
    $Failures.Add($Message) | Out-Null
}

function Get-Text {
    param([string] $RelativePath)
    return Get-Content (Join-Path $RepoRoot $RelativePath) -Raw
}

function Remove-LineComments {
    param([string] $Text)
    return ($Text -split "`r?`n" | ForEach-Object {
        $_ -replace '--.*$', ''
    }) -join "`n"
}

function Assert-Contains {
    param(
        [string] $Text,
        [string] $Needle,
        [string] $Message
    )

    if (-not $Text.Contains($Needle)) {
        Add-Failure $Message
    }
}

Write-Host "Validating Rojo build..."
$buildPath = Join-Path $RepoRoot "build-test.rbxlx"
& rojo build (Join-Path $RepoRoot "default.project.json") --output $buildPath | Out-Null
if (-not (Test-Path $buildPath)) {
    Add-Failure "Rojo build did not produce build-test.rbxlx."
}

Write-Host "Checking deleted legacy module references..."
$allLua = Get-ChildItem $SrcRoot -Recurse -Include *.lua | ForEach-Object {
    [PSCustomObject]@{
        Path = $_.FullName
        Text = Get-Content $_.FullName -Raw
    }
}

foreach ($file in $allLua) {
    $code = Remove-LineComments $file.Text
    if ($code -match 'WaitForChild\("QuestTypes"\)|WaitForChild\("Signal"\)|require\([^)]*(QuestTypes|Signal)') {
        Add-Failure "Legacy module reference found in $($file.Path)."
    }
}

Write-Host "Checking remote contract..."
$questService = Get-Text "src\ServerScriptService\SimpleQuestKitServer\QuestService.lua"
$questController = Get-Text "src\StarterPlayer\StarterPlayerScripts\SimpleQuestKitClient\QuestController.client.lua"
$adminController = Get-Text "src\StarterPlayer\StarterPlayerScripts\SimpleQuestKitClient\AdminDebugController.client.lua"

$requiredRemotes = @(
    "RequestQuestData",
    "ClaimQuest",
    "QuestUpdated",
    "QuestClaimed",
    "OpenQuestUI",
    "ClaimAllCompleted",
    "TrackQuest",
    "UntrackQuest"
)

foreach ($remoteName in $requiredRemotes) {
    Assert-Contains $questService $remoteName "QuestService does not create remote '$remoteName'."
    Assert-Contains $questController $remoteName "QuestController does not wait for remote '$remoteName'."
}

Assert-Contains $questService "AdminQuestDebug" "QuestService does not create the admin debug remote."
Assert-Contains $adminController "AdminQuestDebug" "Admin debug controller does not wait for AdminQuestDebug."

Write-Host "Checking quest ids and prerequisites..."
$configFiles = @(
    "src\ReplicatedStorage\SimpleQuestKit\Config\QuestConfig.lua",
    "src\ReplicatedStorage\SimpleQuestKit\Config\DailyQuestConfig.lua",
    "src\ReplicatedStorage\SimpleQuestKit\Config\WeeklyQuestConfig.lua",
    "src\ReplicatedStorage\SimpleQuestKit\Config\AchievementConfig.lua",
    "src\ReplicatedStorage\SimpleQuestKit\Config\EventQuestConfig.lua"
)

$questIds = New-Object System.Collections.Generic.HashSet[string]
$duplicateQuestIds = New-Object System.Collections.Generic.List[string]
$prerequisites = New-Object System.Collections.Generic.List[object]

foreach ($relativePath in $configFiles) {
    $text = Remove-LineComments (Get-Text $relativePath)
    foreach ($match in [regex]::Matches($text, 'Id\s*=\s*"([^"]+)"')) {
        $id = $match.Groups[1].Value
        if (-not $questIds.Add($id)) {
            $duplicateQuestIds.Add($id) | Out-Null
        }
    }

    foreach ($match in [regex]::Matches($text, 'PrerequisiteQuests\s*=\s*\{([^}]*)\}', [System.Text.RegularExpressions.RegexOptions]::Singleline)) {
        foreach ($idMatch in [regex]::Matches($match.Groups[1].Value, '"([^"]+)"')) {
            $prerequisites.Add([PSCustomObject]@{
                Path = $relativePath
                Id = $idMatch.Groups[1].Value
            }) | Out-Null
        }
    }
}

foreach ($duplicateQuestId in $duplicateQuestIds) {
    Add-Failure "Duplicate quest id '$duplicateQuestId'."
}

foreach ($prerequisite in $prerequisites) {
    if (-not $questIds.Contains($prerequisite.Id)) {
        Add-Failure "Unknown prerequisite '$($prerequisite.Id)' in $($prerequisite.Path)."
    }
}

Write-Host "Checking buyer-facing config defaults..."
$demoConfig = Get-Text "src\ReplicatedStorage\SimpleQuestKit\Config\DemoConfig.lua"
Assert-Contains $demoConfig "UseDataStore = false" "DemoConfig should default UseDataStore to false for Studio safety."
Assert-Contains $demoConfig "EnableAdminDebugPanel = false" "Admin debug panel should default to disabled."

if ($Failures.Count -gt 0) {
    Write-Host ""
    Write-Host "Validation failed:" -ForegroundColor Red
    foreach ($failure in $Failures) {
        Write-Host " - $failure" -ForegroundColor Red
    }
    exit 1
}

Write-Host "All SimpleQuestKit validation checks passed." -ForegroundColor Green
