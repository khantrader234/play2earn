# Create directories if they don't exist
New-Item -ItemType Directory -Force -Path "assets/sounds"
New-Item -ItemType Directory -Force -Path "assets/images"
New-Item -ItemType Directory -Force -Path "assets/fonts"

# Download sound effects
$soundUrls = @{
    "breathing_normal.mp3" = "https://freesound.org/people/OwlStorm/sounds/151206/download/"
    "breathing_stressed.mp3" = "https://freesound.org/people/giddster/sounds/336530/download/"
    "breathing_breakdown.mp3" = "https://freesound.org/people/ceberation/sounds/235519/download/"
    "meeting_ambience.mp3" = "https://freesound.org/people/DiArchangeli/sounds/108695/download/"
    "background_music.mp3" = "https://freesound.org/people/richwise/sounds/456207/download/"
}

foreach ($sound in $soundUrls.GetEnumerator()) {
    $outFile = "assets/sounds/$($sound.Key)"
    Write-Host "Downloading $($sound.Key)..."
    Invoke-WebRequest -Uri $sound.Value -OutFile $outFile
}

# Download Roboto fonts
$fontUrls = @{
    "Roboto-Regular.ttf" = "https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Regular.ttf"
    "Roboto-Bold.ttf" = "https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Bold.ttf"
}

foreach ($font in $fontUrls.GetEnumerator()) {
    $outFile = "assets/fonts/$($font.Key)"
    Write-Host "Downloading $($font.Key)..."
    Invoke-WebRequest -Uri $font.Value -OutFile $outFile
}

Write-Host "Downloads complete!"
Write-Host "Note: You still need to create or download a character sprite (normie.png) and place it in the assets/images directory." 