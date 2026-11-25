<#
.SYNOPSIS
    OmniFlow AI Environment Setup and Verification Script
.DESCRIPTION
    Validates host dependencies (Docker, PostgreSQL), checks directories, and bootstraps configuration.
#>

[CmdletBinding()]
param(
    [switch]$SkipDbSeed
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  OmniFlow AI - Setup & Verification      " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Check Required Directories
$dirs = @("reports", "n8n-data", "database", "workflows", "docs")
foreach ($d in $dirs) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        Write-Host "[+] Created directory: $d" -ForegroundColor Green
    } else {
        Write-Host "[OK] Directory present: $d" -ForegroundColor DarkGray
    }
}

# 2. Check .env configuration
if (-not (Test-Path ".env")) {
    if (Test-Path ".env.example") {
        Copy-Item ".env.example" ".env"
        Write-Host "[!] Created .env from .env.example. Please review your credentials." -ForegroundColor Yellow
    }
} else {
    Write-Host "[OK] .env file detected" -ForegroundColor DarkGray
}

# 3. Check Docker status
Write-Host "`nChecking Docker engine..." -ForegroundColor Cyan
try {
    $dockerVersion = docker --version
    Write-Host "[OK] Docker detected: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Warning "Docker command not found or Docker Desktop is not running."
}

# 4. Check PostgreSQL service / port 5432
Write-Host "`nChecking PostgreSQL (Port 5432)..." -ForegroundColor Cyan
$portActive = Get-NetTCPConnection -LocalPort 5432 -State Listen -ErrorAction SilentlyContinue
if ($portActive) {
    Write-Host "[OK] PostgreSQL is actively listening on port 5432." -ForegroundColor Green
} else {
    Write-Warning "Port 5432 is not currently listening. Ensure PostgreSQL is started."
}

# 5. Database Schema Application Guidance
Write-Host "`nDatabase Setup Instructions:" -ForegroundColor Cyan
Write-Host "To initialize tables and sample data in your local PostgreSQL database, execute:" -ForegroundColor White
Write-Host "  psql -U postgres -d postgres -f database/schema.sql" -ForegroundColor Yellow
Write-Host "  psql -U postgres -d postgres -f database/sample_data.sql" -ForegroundColor Yellow

# 6. Service Deployment Guidance
Write-Host "`nDeployment Instructions:" -ForegroundColor Cyan
Write-Host "To launch or run n8n and Gotenberg via Docker Compose:" -ForegroundColor White
Write-Host "  docker compose up -d" -ForegroundColor Yellow
Write-Host "`nAccess URLs:" -ForegroundColor White
Write-Host "  n8n UI:    http://localhost:5678" -ForegroundColor Green
Write-Host "  Gotenberg: http://localhost:3000" -ForegroundColor Green

Write-Host "`nSetup verification complete." -ForegroundColor Cyan
