#requires -Version 7.0
param(
    [string]$WorkspaceRoot = 'D:\novel',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$workspacePath = (Resolve-Path -LiteralPath $WorkspaceRoot).Path.TrimEnd('\')
$workspacePrefix = $workspacePath + '\'

function Get-CheckedPath([string]$RelativePath) {
    $absolutePath = [System.IO.Path]::GetFullPath((Join-Path $workspacePath $RelativePath))
    if (-not $absolutePath.StartsWith($workspacePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is outside the workspace: $absolutePath"
    }
    return $absolutePath
}

# Nested sources precede their parents so every original file gets one destination.
$moves = @(
    @{ From='策划工作\v3_详细设定与剧本'; To='docs\design\v3' },
    @{ From='策划工作\前传天机_阅读报告.md'; To='docs\reference\reading_reports\前传天机_阅读报告.md' },
    @{ From='策划工作\纯阳破城_阅读报告.md'; To='docs\reference\reading_reports\纯阳破城_阅读报告.md' },
    @{ From='策划工作\龙游劫波_阅读报告.md'; To='docs\reference\reading_reports\龙游劫波_阅读报告.md' },
    @{ From='策划工作\天道_阅读报告.md'; To='docs\reference\reading_reports\天道_阅读报告.md' },
    @{ From='策划工作\40–60小时改编审校建议_龙游劫波.md'; To='docs\reference\reading_reports\40–60小时改编审校建议_龙游劫波.md' },
    @{ From='策划工作\v2\预览'; To='archive\preview_cache\v2' },
    @{ From='策划工作\v2'; To='archive\design_history\v2' },
    @{ From='策划工作\预览'; To='archive\preview_cache\v1_draft' },
    @{ From='策划工作\终稿预览'; To='archive\preview_cache\v1_final' },
    @{ From='策划工作'; To='archive\design_history\v1' },
    @{ From='昆仑.txt'; To='references\novel\昆仑.txt' },
    @{ From='output\pdf\昆仑_武侠RPG完整策划案_v1.0.html'; To='archive\exports\v1\昆仑_武侠RPG完整策划案_v1.0.html' },
    @{ From='output\pdf\昆仑_武侠RPG完整策划案_v1.0.pdf'; To='archive\exports\v1\昆仑_武侠RPG完整策划案_v1.0.pdf' },
    @{ From='output\pdf\昆仑_像素2D完整策划案_v2.0.html'; To='archive\exports\v2\昆仑_像素2D完整策划案_v2.0.html' },
    @{ From='output\pdf\昆仑_像素2D完整策划案_v2.0.pdf'; To='archive\exports\v2\昆仑_像素2D完整策划案_v2.0.pdf' }
)

foreach ($move in $moves) {
    $move.Source = Get-CheckedPath $move.From
    $move.Destination = Get-CheckedPath $move.To
    if (-not (Test-Path -LiteralPath $move.Source)) { throw "Missing source: $($move.Source)" }
    if (Test-Path -LiteralPath $move.Destination) { throw "Destination already exists: $($move.Destination)" }
}

if (-not $Apply) {
    $moves | ForEach-Object { [PSCustomObject]@{Source=$_.From;Destination=$_.To} } | Format-Table -AutoSize
    return
}

$manifestPath = Get-CheckedPath 'docs\workspace\v3_workspace_move_manifest_2026-10-13.csv'
$verificationPath = Get-CheckedPath 'docs\workspace\v3_workspace_integrity_2026-10-13.json'
if ((Test-Path -LiteralPath $manifestPath) -or (Test-Path -LiteralPath $verificationPath)) {
    throw 'Migration records already exist; this script is for a single migration.'
}

$rows = [System.Collections.Generic.List[object]]::new()
$registeredPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($move in $moves) {
    $sourceItem = Get-Item -LiteralPath $move.Source
    $files = if ($sourceItem.PSIsContainer) { @(Get-ChildItem -LiteralPath $move.Source -Recurse -File -Force) } else { @($sourceItem) }
    foreach ($file in $files) {
        if (-not $file.FullName.StartsWith($workspacePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Unexpected file outside workspace: $($file.FullName)"
        }
        if (-not $registeredPaths.Add($file.FullName)) { continue }
        $targetPath = if ($sourceItem.PSIsContainer) {
            $relativeName = $file.FullName.Substring($move.Source.Length).TrimStart([char[]]'\/')
            [System.IO.Path]::GetFullPath((Join-Path $move.Destination $relativeName))
        } else { $move.Destination }
        if (-not $targetPath.StartsWith($workspacePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Unexpected destination outside workspace: $targetPath"
        }
        $rows.Add([PSCustomObject]@{
            Action='move';Source=$file.FullName;Destination=$targetPath
            Bytes=$file.Length;SHA256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        })
    }
}

# Verify the IDE files and concept images that remain in their current locations.
foreach ($relativeDirectory in @('.idea','assets\concepts')) {
    $preservedDirectory = Get-CheckedPath $relativeDirectory
    if (-not (Test-Path -LiteralPath $preservedDirectory)) { continue }
    foreach ($file in Get-ChildItem -LiteralPath $preservedDirectory -Recurse -File -Force) {
        $rows.Add([PSCustomObject]@{
            Action='preserve';Source=$file.FullName;Destination=$file.FullName
            Bytes=$file.Length;SHA256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        })
    }
}

New-Item -ItemType Directory -Path (Split-Path -Parent $manifestPath) -Force | Out-Null
$rows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding utf8BOM

foreach ($move in $moves) {
    $targetParent = Split-Path -Parent $move.Destination
    if (-not $targetParent.StartsWith($workspacePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Unexpected target parent: $targetParent"
    }
    New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
    if (Test-Path -LiteralPath $move.Destination) { throw "Destination changed during migration: $($move.Destination)" }
    Move-Item -LiteralPath $move.Source -Destination $move.Destination
}

$failures = [System.Collections.Generic.List[string]]::new()
foreach ($row in $rows) {
    if (-not (Test-Path -LiteralPath $row.Destination -PathType Leaf)) {
        $failures.Add("Missing target: $($row.Destination)");continue
    }
    $newItem = Get-Item -LiteralPath $row.Destination
    $newHash = (Get-FileHash -LiteralPath $row.Destination -Algorithm SHA256).Hash
    if (($newItem.Length -ne $row.Bytes) -or ($newHash -ne $row.SHA256)) {
        $failures.Add("Content mismatch: $($row.Destination)")
    }
}

$verification = [PSCustomObject]@{
    CheckedAt=(Get-Date).ToUniversalTime().ToString('o')
    Status=if ($failures.Count -eq 0) { 'verified' } else { 'failed' }
    Workspace=$workspacePath
    MoveOperations=$moves.Count
    MovedFiles=@($rows | Where-Object Action -eq 'move').Count
    PreservedFiles=@($rows | Where-Object Action -eq 'preserve').Count
    V3OriginalFiles=@($rows | Where-Object { $_.Destination.StartsWith((Get-CheckedPath 'docs\design\v3')+'\', [System.StringComparison]::OrdinalIgnoreCase) }).Count
    VerifiedBytes=($rows | Measure-Object Bytes -Sum).Sum
    Manifest=$manifestPath
    Failures=@($failures)
}
$verification | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $verificationPath -Encoding utf8
$verification | ConvertTo-Json -Depth 4
if ($failures.Count -gt 0) { throw 'Workspace migration integrity check failed; consult the verification record.' }
