# Extract ALL base64 images from HTML (both src and onclick attributes)

$htmlFile = "index.html"
$mediaDir = "media"

# Create media directory if it doesn't exist
if (-not (Test-Path $mediaDir)) {
    New-Item -ItemType Directory -Path $mediaDir | Out-Null
}

# Read HTML file
$htmlContent = Get-Content $htmlFile -Raw

# Counter for image numbering
$imageCounter = 1

# Pattern 1: src="data:image/([^;]+);base64,([^"]+)" - Images in src attributes
Write-Host "Extracting images from src attributes..."
$srcPattern = 'src="data:image/([^;]+);base64,([^"]+)"'
$srcMatches = [regex]::Matches($htmlContent, $srcPattern)

foreach ($match in $srcMatches) {
    $imageFormat = $match.Groups[1].Value
    $base64Data = $match.Groups[2].Value
    
    $fileName = "image-$imageCounter.jpg"
    $filePath = Join-Path $mediaDir $fileName
    
    try {
        $imageBytes = [Convert]::FromBase64String($base64Data)
        [IO.File]::WriteAllBytes($filePath, $imageBytes)
        Write-Host "[OK] Saved $fileName (from src attribute)"
        
        # Replace in HTML content
        $oldString = $match.Value
        $newString = "src=`"media/$fileName`""
        $htmlContent = $htmlContent.Replace($oldString, $newString)
        
        $imageCounter++
    } catch {
        Write-Host "[ERROR] Failed to process $fileName"
    }
}

# Pattern 2: onclick="openLb('data:image/([^;]+);base64,([^']+)') - Images in onclick attributes
Write-Host "Extracting images from onclick attributes..."
$onclickPattern = "onclick=`"openLb\('data:image/([^;]+);base64,([^']+)'\)"
$onclickMatches = [regex]::Matches($htmlContent, $onclickPattern)

foreach ($match in $onclickMatches) {
    $imageFormat = $match.Groups[1].Value
    $base64Data = $match.Groups[2].Value
    
    $fileName = "image-$imageCounter.jpg"
    $filePath = Join-Path $mediaDir $fileName
    
    try {
        $imageBytes = [Convert]::FromBase64String($base64Data)
        [IO.File]::WriteAllBytes($filePath, $imageBytes)
        Write-Host "[OK] Saved $fileName (from onclick attribute)"
        
        # Replace in HTML content
        $oldString = $match.Value
        $newString = "onclick=`"openLb('media/$fileName')`""
        $htmlContent = $htmlContent.Replace($oldString, $newString)
        
        $imageCounter++
    } catch {
        Write-Host "[ERROR] Failed to process $fileName"
    }
}

# Write updated HTML back to file
Set-Content -Path $htmlFile -Value $htmlContent -Encoding UTF8
Write-Host ""
Write-Host "[OK] HTML updated successfully!"
Write-Host "[OK] Total images extracted: $($imageCounter - 1)"
