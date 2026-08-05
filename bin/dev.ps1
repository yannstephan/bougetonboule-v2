# Equivalent Windows de bin/dev.
#
# bin/dev est un script sh qui s'appuie sur foreman, lequel a besoin de fork() :
# rien de tout ca n'existe en natif sous Windows. On lance donc les deux process
# nous-memes, dans le terminal courant (les logs Rails et Vite s'y melangent,
# exactement comme le ferait foreman).
#
#   .\bin\dev.ps1              # dans ce terminal, Ctrl+C arrete les deux
#   .\bin\dev.ps1 -NewWindows  # une fenetre par process, si on prefere les separer

param([switch]$NewWindows)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$port = if ($env:PORT) { $env:PORT } else { '3000' }

# Le PATH d'un shell ouvert avant l'installation de Ruby/Node est encore l'ancien :
# on le relit dans le registre plutot que de demander un redemarrage du terminal.
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [Environment]::GetEnvironmentVariable('Path', 'User')

foreach ($exe in 'ruby', 'node') {
  if (-not (Get-Command $exe -ErrorAction SilentlyContinue)) {
    throw "$exe est introuvable dans le PATH. Voir la section Windows du CLAUDE.md."
  }
}

# -NoNewWindow : les enfants heritent de cette console, donc leurs logs arrivent ici
# et le Ctrl+C de la console leur est transmis directement.
$window = if ($NewWindows) { @{} } else { @{ NoNewWindow = $true } }

$procs = @()
try {
  $procs += Start-Process -FilePath 'ruby' -ArgumentList 'bin/vite', 'dev' `
                          -WorkingDirectory $root -PassThru @window
  $rails  = Start-Process -FilePath 'ruby' -ArgumentList 'bin/rails', 's', '-p', $port `
                          -WorkingDirectory $root -PassThru @window
  $procs += $rails

  Write-Host ""
  Write-Host "  Vite   http://localhost:3036" -ForegroundColor DarkCyan
  Write-Host "  Rails  http://localhost:$port" -ForegroundColor Green
  Write-Host "  Demo   yann@btb.test / odyssea2027" -ForegroundColor DarkGray
  Write-Host ""

  Wait-Process -Id $rails.Id
}
finally {
  # taskkill /T : bin/vite lance un node enfant, qui garderait le port 3036 sinon.
  foreach ($p in $procs) {
    if ($p -and -not $p.HasExited) {
      taskkill /PID $p.Id /T /F 2>&1 | Out-Null
    }
  }
}
