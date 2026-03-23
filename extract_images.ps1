# Extract base64 images from HTML and save as files
$htmlFile = Join-Path $PSScriptRoot "index.html"
$mediaDir = Join-Path $PSScriptRoot "media"

# Create media directory if it doesn't exist
if (-not (Test-Path $mediaDir)) {
    New-Item -ItemType Directory -Path $mediaDir -Force | Out-Null
}

# Read HTML content
$htmlContent = Get-Content $htmlFile -Raw -Encoding UTF8

# Pattern to match base64 images
$pattern = 'src="data:image/([^;]+);base64,([^"]+)"'

# Find all matches
$regex = [regex]::new($pattern)
$matches = $regex.Matches($htmlContent)

$imageCount = @{}
$replacements = @()

Write-Host "Extracting images..."

foreach ($match in $matches) {
    $imageType = $match.Groups[1].Value
    $base64Data = $match.Groups[2].Value
    $fullDataUri = $match.Groups[0].Value
    
    # Determine extension
    $ext = if ($imageType -eq 'jpeg') { 'jpg' } else { $imageType }
    
    # Generate filename
    if (-not $imageCount.ContainsKey($ext)) {
        $imageCount[$ext] = 1
        $filename = "image-1.$ext"
    } else {
        $imageCount[$ext]++
        $filename = "image-$($imageCount[$ext]).$ext"
    }
    
    $imagePath = Join-Path $mediaDir $filename
    
    try {
        # Decode base64 and save
        $imageBytes = [Convert]::FromBase64String($base64Data)
        [IO.File]::WriteAllBytes($imagePath, $imageBytes)
        Write-Host "[OK] Saved $filename"
        
        # Store replacement info
        $replacements += @{
            Old = $fullDataUri
            New = "src=`"media/$filename`""
        }
    }
    catch {
        Write-Host "[ERROR] Error saving ${filename}: $_"
    }
}

# Replace all base64 src with file references
$updatedHtml = $htmlContent
foreach ($replacement in $replacements) {
    $updatedHtml = $updatedHtml -replace [regex]::Escape($replacement.Old), $replacement.New
}

# Write updated HTML back
Set-Content -Path $htmlFile -Value $updatedHtml -Encoding UTF8

Write-Host ""
Write-Host "[OK] HTML updated successfully!"
Write-Host "[OK] $($replacements.Count) images extracted and saved to media folder"
