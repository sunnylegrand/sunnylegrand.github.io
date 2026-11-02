# EasyEdit Windows launcher
# First run downloads the editing engine (~32MB); afterwards fully offline.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root
$port = 8901

$engineDir = Join-Path $root "vendor"
$base1 = "https://cdn.jsdelivr.net/npm"
$base2 = "https://unpkg.com"
$files = @(
  "@ffmpeg/ffmpeg@0.12.10/dist/umd/ffmpeg.js",
  "@ffmpeg/ffmpeg@0.12.10/dist/umd/814.ffmpeg.js",
  "@ffmpeg/util@0.12.1/dist/umd/index.js",
  "@ffmpeg/core@0.12.6/dist/umd/ffmpeg-core.js",
  "@ffmpeg/core@0.12.6/dist/umd/ffmpeg-core.wasm"
)
$wasmMin = 30000000

function Get-FileSize($p) {
  if (Test-Path $p) { return (Get-Item $p).Length }
  return 0
}

$needDl = $false
foreach ($f in $files) {
  $dest = Join-Path $engineDir $f
  $sz = Get-FileSize $dest
  if ($sz -eq 0) { $needDl = $true; break }
  if ($f.EndsWith("ffmpeg-core.wasm") -and $sz -lt $wasmMin) { $needDl = $true; break }
}

if ($needDl) {
  Write-Host "First run: downloading editing engine (~32MB, one time only)..."
  foreach ($f in $files) {
    $dest = Join-Path $engineDir $f
    $sz = Get-FileSize $dest
    $alreadyOk = ($sz -gt 0) -and -not ($f.EndsWith("ffmpeg-core.wasm") -and $sz -lt $wasmMin)
    if ($alreadyOk) { continue }
    $dir = Split-Path -Parent $dest
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    $ok = $false
    foreach ($base in @($base1, $base2)) {
      Write-Host "Downloading $f ..."
      try {
        $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
        if ($curl) {
          & curl.exe -L --fail --progress-bar -o "$dest.tmp" "$base/$f"
        } else {
          Invoke-WebRequest -Uri "$base/$f" -OutFile "$dest.tmp"
        }
        Move-Item "$dest.tmp" $dest -Force
        $ok = $true
        break
      } catch {
        Write-Host "This source failed, trying backup source..."
        if (Test-Path "$dest.tmp") { Remove-Item "$dest.tmp" -Force }
      }
    }
    if (-not $ok) {
      Write-Host ""
      Write-Host "Download failed: $f"
      Write-Host "Check your network connection and run again."
      Read-Host "Press Enter to exit"
      exit 1
    }
  }
  Write-Host "Engine ready. No internet needed from now on."
  Write-Host ""
}

function Test-PortFree($p) {
  try {
    $l = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $p)
    $l.Start(); $l.Stop()
    return $true
  } catch { return $false }
}
if (-not (Test-PortFree $port)) { $port = 8902 }

$mime = @{
  ".html" = "text/html; charset=utf-8"
  ".js"   = "text/javascript"
  ".wasm" = "application/wasm"
  ".txt"  = "text/plain; charset=utf-8"
  ".md"   = "text/plain; charset=utf-8"
  ".json" = "application/json"
  ".css"  = "text/css"
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$port/")
$listener.Start()
$rootPrefix = $root.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar

Write-Host "EasyEdit is running at http://127.0.0.1:$port/"
Write-Host "Your browser should open automatically. Close this window when done."
Write-Host ""
Start-Process "http://127.0.0.1:$port/"

try {
  while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    try {
      $rel = [uri]::UnescapeDataString($ctx.Request.Url.LocalPath.TrimStart('/'))
      if ([string]::IsNullOrEmpty($rel)) { $rel = "index.html" }
      $full = [IO.Path]::GetFullPath((Join-Path $root $rel))
      $resp = $ctx.Response
      if ($full.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path $full -PathType Leaf)) {
        $bytes = [IO.File]::ReadAllBytes($full)
        $ext = [IO.Path]::GetExtension($full).ToLower()
        if ($mime.ContainsKey($ext)) { $resp.ContentType = $mime[$ext] } else { $resp.ContentType = "application/octet-stream" }
        $resp.ContentLength64 = $bytes.Length
        $resp.OutputStream.Write($bytes, 0, $bytes.Length)
      } else {
        $resp.StatusCode = 404
      }
    } catch {
      try { $ctx.Response.StatusCode = 500 } catch {}
    } finally {
      $ctx.Response.Close()
    }
  }
} finally {
  $listener.Stop()
}
