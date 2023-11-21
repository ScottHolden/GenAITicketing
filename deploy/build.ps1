$sourceBicep = "deploy.bicep"
$targetFile = "deploy.generated.json"

if (-not (Test-Path $sourceBicep)) {
    Write-Error "Can't find $sourceBicep"
    return;
}

Write-Host "Checking for Bicep updates..."
& az bicep upgrade
if ($LASTEXITCODE -ne 0) {
    Write-Error "Error whilst upgrading Bicep, is the Azure CLI & Bicep installed?" -ErrorAction Stop
}

Write-Host "Building $sourceBicep in $(Split-Path -Path $PWD -Leaf)"
& az bicep build -f "$sourceBicep" --outfile "$targetFile"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Unable to build $sourceBicep!" -ErrorAction Stop
}