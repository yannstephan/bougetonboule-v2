# Equivalent Windows de bin/dev.
#
# bin/dev est un script sh qui s'appuie sur foreman, lequel a besoin de fork() :
# rien de tout ca n'existe en natif sous Windows. On lance donc les deux process
# nous-memes, dans le terminal courant (les logs Rails et Vite s'y melangent,
# exactement comme le ferait foreman).
#
#   .\bin\dev.ps1              # dans ce terminal, Ctrl+C arrete les deux
#   .\bin\dev.ps1 -NewWindows  # une fenetre par process, si on prefere les separer
#   .\bin\dev.ps1 -Stop        # arrete les serveurs et rend la main

param([switch]$NewWindows, [switch]$Stop)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$port = if ($env:PORT) { $env:PORT } else { '3000' }

# Le PATH d'un shell ouvert avant l'installation de Ruby/Node est encore l'ancien :
# on le relit dans le registre plutot que de demander un redemarrage du terminal.
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [Environment]::GetEnvironmentVariable('Path', 'User')

# Un serveur lance dans un autre terminal (ou par un agent) n'a pas de Ctrl+C
# accessible : on le retrouve pour pouvoir relancer sans redemarrer la machine.
# Deux pistes, parce qu'aucune ne suffit seule : le process qui ecoute le port
# (le node enfant de Vite, pas son parent ruby) et la ligne de commande (le ruby
# parent, qui lui n'ecoute rien). On ne tue que du ruby/node, jamais un process
# tiers qui aurait pris le 3000.
function Get-DevServerPids {
  $found = @()

  $listening = Get-NetTCPConnection -State Listen -LocalPort $port, 3036 -ErrorAction SilentlyContinue
  foreach ($conn in $listening) {
    $p = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
    if ($p -and $p.Name -in 'ruby', 'node') { $found += $p.Id }
  }

  $running = Get-CimInstance Win32_Process -Filter "Name='ruby.exe' OR Name='node.exe'" -ErrorAction SilentlyContinue
  foreach ($p in $running) {
    if ($p.CommandLine -and $p.CommandLine -match 'bin[\\/](rails|vite)') { $found += $p.ProcessId }
  }

  $found | Sort-Object -Unique
}

function Stop-DevServers {
  $ids = @(Get-DevServerPids)
  foreach ($id in $ids) {
    # /T tue aussi les enfants (le node de Vite garderait le 3036), donc le PID
    # suivant de la liste est parfois deja mort : on passe par cmd, dont le stderr
    # ne remonte pas dans PowerShell — sinon $ErrorActionPreference='Stop' avorte
    # l'arret a mi-parcours sur un "processus introuvable" sans consequence.
    cmd /c "taskkill /PID $id /T /F >nul 2>&1"
  }
  if ($ids.Count) {
    Write-Host "  $($ids.Count) process arrete(s)." -ForegroundColor DarkGray
    Start-Sleep -Milliseconds 500
  }
  $ids.Count
}

if ($Stop) {
  if (-not (Stop-DevServers)) { Write-Host "  Aucun serveur en cours." -ForegroundColor DarkGray }
  return
}

foreach ($exe in 'ruby', 'node') {
  if (-not (Get-Command $exe -ErrorAction SilentlyContinue)) {
    throw "$exe est introuvable dans le PATH. Voir la section Windows du CLAUDE.md."
  }
}

# Relancer sans avoir arrete proprement est le cas courant : on libere les ports
# plutot que d'echouer sur un "Address already in use".
Stop-DevServers | Out-Null

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
  foreach ($p in $procs) {
    if ($p -and -not $p.HasExited) { cmd /c "taskkill /PID $($p.Id) /T /F >nul 2>&1" }
  }
}
