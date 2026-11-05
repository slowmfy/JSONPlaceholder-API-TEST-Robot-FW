<#
.SYNOPSIS
    Lance l'application web testée (API FastAPI + interface Angular), située dans app/.

.DESCRIPTION
    Prépare ce qui manque (dépendances Python dans venv/, dépendances Angular,
    compilation de l'interface), puis lance l'application. Les étapes déjà faites
    sont sautées : les lancements suivants sont immédiats.

    Prérequis : l'environnement virtuel venv/ du projet (voir README, étape 3).

.PARAMETER Mode
    web     (défaut) interface sur http://127.0.0.1:8000
    dev     API + serveur Angular avec rechargement automatique (http://localhost:4200)

.PARAMETER Rebuild
    Force la recompilation de l'interface Angular.

.PARAMETER NoBrowser
    N'ouvre pas le navigateur automatiquement.

.EXAMPLE
    .\start-app.ps1
    .\start-app.ps1 dev
    .\start-app.ps1 -Rebuild
#>
param(
    [ValidateSet('web', 'dev')]
    [string]$Mode = 'web',
    [switch]$Rebuild,
    [switch]$NoBrowser
)

$ErrorActionPreference = 'Stop'

$Root = $PSScriptRoot
$App = Join-Path $Root 'app'
$Python = Join-Path $Root 'venv\Scripts\python.exe'
$Frontend = Join-Path $App 'frontend'
$FrontendIndex = Join-Path $Frontend 'dist\frontend\browser\index.html'

function Write-Step([string]$Message) {
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Stop-WithError([string]$Message) {
    Write-Host "Erreur : $Message" -ForegroundColor Red
    exit 1
}

function Invoke-Checked([scriptblock]$Command, [string]$ErrorMessage) {
    & $Command
    if ($LASTEXITCODE -ne 0) { Stop-WithError $ErrorMessage }
}

# ---------- Python ----------

function Initialize-Python {
    if (-not (Test-Path $Python)) {
        Stop-WithError "environnement virtuel introuvable. Créez-le d'abord : python -m venv venv ; .\venv\Scripts\pip install -r requirements.txt"
    }
    # Les dépendances ne sont réinstallées que si requirements.txt a changé.
    $stamp = Join-Path $Root 'venv\.requirements-hash'
    $hash = (Get-FileHash (Join-Path $Root 'requirements.txt')).Hash
    if (-not (Test-Path $stamp) -or (Get-Content $stamp) -ne $hash) {
        Write-Step 'Installation des dépendances Python'
        Invoke-Checked { & $Python -m pip install --disable-pip-version-check -q -r (Join-Path $Root 'requirements.txt') } 'échec de pip install.'
        Set-Content -Path $stamp -Value $hash
    }
}

# ---------- Angular ----------

function Initialize-Frontend([bool]$Build) {
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        Stop-WithError "Node.js est introuvable. Installez-le depuis https://nodejs.org"
    }
    if (-not (Test-Path (Join-Path $Frontend 'node_modules'))) {
        Write-Step 'Installation des dépendances Angular (npm ci)'
        Push-Location $Frontend
        try { Invoke-Checked { npm ci --no-fund --no-audit } 'échec de npm ci.' }
        finally { Pop-Location }
    }
    if (-not $Build) { return }

    # Recompile seulement si le build est absent ou plus ancien que les sources.
    $needsBuild = $Rebuild -or -not (Test-Path $FrontendIndex)
    if (-not $needsBuild) {
        $builtAt = (Get-Item $FrontendIndex).LastWriteTime
        $newest = Get-ChildItem (Join-Path $Frontend 'src') -Recurse -File |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        $needsBuild = $newest.LastWriteTime -gt $builtAt
    }
    if ($needsBuild) {
        Write-Step "Compilation de l'interface Angular"
        Push-Location $Frontend
        try { Invoke-Checked { npm run build --silent } 'échec de la compilation Angular.' }
        finally { Pop-Location }
    }
}

# ---------- Serveur web ----------

function Get-WebUrl {
    # Hôte et port lus dans app/config.py pour ne pas les dupliquer ici.
    Push-Location $App
    try { $address = & $Python -c "import config; print(f'{config.WEB_HOST}:{config.WEB_PORT}')" }
    finally { Pop-Location }
    return "http://$address"
}

function Assert-PortFree([string]$Url) {
    $port = ([Uri]$Url).Port
    if (Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue) {
        Stop-WithError "le port $port est déjà utilisé. L'application tourne peut-être déjà : ouvrez $Url"
    }
}

function Stop-Server([System.Diagnostics.Process]$Process) {
    if (-not $Process.HasExited) { Stop-Process -Id $Process.Id -Force }
}

function Wait-Server([string]$Url, [System.Diagnostics.Process]$Process) {
    for ($i = 0; $i -lt 40; $i++) {
        if ($Process.HasExited) { Stop-WithError "le serveur s'est arrêté au démarrage (voir app\web.log)." }
        try {
            Invoke-WebRequest "$Url/api/languages" -UseBasicParsing -TimeoutSec 1 | Out-Null
            return
        }
        catch { Start-Sleep -Milliseconds 500 }
    }
    Stop-Server $Process
    Stop-WithError 'le serveur ne répond pas après 20 secondes.'
}

function Start-WebServer([string]$Url, [bool]$NewWindow) {
    Assert-PortFree $Url
    Write-Step "Démarrage de l'API web sur $Url"
    $options = @{ FilePath = $Python; ArgumentList = 'web_api.py'; WorkingDirectory = $App; PassThru = $true }
    if (-not $NewWindow) { $options.NoNewWindow = $true }
    $server = Start-Process @options
    Wait-Server $Url $server
    return $server
}

# ---------- Modes ----------

Initialize-Python

switch ($Mode) {
    'web' {
        Initialize-Frontend -Build $true
        $url = Get-WebUrl
        $server = Start-WebServer $url -NewWindow $false
        try {
            if (-not $NoBrowser) { Start-Process $url }
            Write-Host ''
            Write-Host "Application disponible sur $url  (Ctrl+C pour arrêter)" -ForegroundColor Green
            Write-Host ''
            $server.WaitForExit()
        }
        finally {
            Stop-Server $server
        }
    }

    'dev' {
        Initialize-Frontend -Build $false
        # L'API tourne dans sa propre fenêtre ; ng serve dans celle-ci.
        $server = Start-WebServer (Get-WebUrl) -NewWindow $true
        try {
            Push-Location $Frontend
            if ($NoBrowser) { npm start } else { npm start -- --open }
        }
        finally {
            Pop-Location
            Stop-Server $server
        }
    }
}
