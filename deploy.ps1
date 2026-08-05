# Custom Deployment Script for Muslim Platform
# Auto-sync to GitHub & Firebase Hosting / Services

param (
    [string]$commitMessage = "Auto update: code & configuration sync"
)

Write-Host "🚀 Starting Deployment Process..." -ForegroundColor Green

# 1. Step 1: Run Dart / Flutter Checks
Write-Host "🔍 [1/4] Running Code Analysis..." -ForegroundColor Yellow
dart analyze lib/
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Code analysis failed! Deployment aborted." -ForegroundColor Red
    exit 1
}

# 2. Step 2: Push Changes to GitHub
Write-Host "📦 [2/4] Syncing Code to GitHub..." -ForegroundColor Cyan
git add .
git commit -m "$commitMessage"
git push origin main
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ GitHub Sync Completed!" -ForegroundColor Green
} else {
    Write-Host "⚠️ GitHub Push Warning (check git status)." -ForegroundColor Yellow
}

# 3. Step 3: Build Web / Firebase Assets (If applicable)
Write-Host "🔨 [3/4] Preparing Firebase Deployment..." -ForegroundColor Cyan
# If deploying Firebase Hosting (Web version)
if (Test-Path "web") {
    flutter build web --release
}

# 4. Step 4: Deploy to Firebase
Write-Host "🔥 [4/4] Deploying to Firebase..." -ForegroundColor Cyan
firebase deploy
if ($LASTEXITCODE -eq 0) {
    Write-Host "🎉 Firebase Deployment Successful!" -ForegroundColor Green
} else {
    Write-Host "❌ Firebase Deployment Failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✨ ALL DONE! GitHub and Firebase are fully updated." -ForegroundColor Green