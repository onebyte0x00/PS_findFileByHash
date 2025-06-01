param (
    [Parameter(Mandatory=$true)]
    [string]$HashValue,
    [string]$Path = "C:\",
    [ValidateSet("SHA1","SHA256","SHA384","SHA512","MD5")]
    [string]$Algorithm = "SHA256"
)

# Check if path exists
if (-not (Test-Path -Path $Path)) {
    Write-Error "Path '$Path' does not exist."
    exit 1
}

# Confirm if scanning a large directory
if ($Path -match '^[a-z]:\\$') {
    $confirmation = Read-Host "WARNING: Scanning the entire $Path drive may take hours. Continue? (y/n)"
    if ($confirmation -ne 'y') { exit }
}

Write-Host "Searching for hash $HashValue ($Algorithm) in $Path..." -ForegroundColor Cyan

Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        $fileHash = (Get-FileHash -Path $_.FullName -Algorithm $Algorithm -ErrorAction Stop).Hash
        if ($fileHash -eq $HashValue) {
            Write-Host "Match found: $($_.FullName)" -ForegroundColor Green
            [PSCustomObject]@{
                Path = $_.FullName
                Size = "{0:N2} MB" -f ($_.Length / 1MB)
                LastModified = $_.LastWriteTime
                Hash = $fileHash
                Algorithm = $Algorithm
            }
        }
    }
    catch {
        Write-Warning "Could not compute hash for $($_.FullName): $($_.Exception.Message)"
    }
}
