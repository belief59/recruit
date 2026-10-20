# Local web server for the recruit helper PWA (http://localhost:5179/)
# - Serves only the app files listed below (never PDFs/JSON in this folder)
# - Accepts local requests only
# - Exits by itself after 30 minutes without requests (the installed app keeps working offline)
$port = 5179
$root = $PSScriptRoot
$files = @{
  '/'                     = @('index.html',           'text/html; charset=utf-8')
  '/index.html'           = @('index.html',           'text/html; charset=utf-8')
  '/manifest.webmanifest' = @('manifest.webmanifest', 'application/manifest+json; charset=utf-8')
  '/sw.js'                = @('sw.js',                'application/javascript; charset=utf-8')
  '/icon-192.png'         = @('icon-192.png',         'image/png')
  '/icon-512.png'         = @('icon-512.png',         'image/png')
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
try { $listener.Start() } catch { Write-Host "Port $port is already in use."; exit 1 }

while ($listener.IsListening) {
  $async = $listener.BeginGetContext($null, $null)
  if (-not $async.AsyncWaitHandle.WaitOne(1800000)) { break }
  $ctx = $listener.EndGetContext($async)
  $req = $ctx.Request; $res = $ctx.Response
  try {
    $entry = $files[$req.Url.AbsolutePath]
    if (-not $req.IsLocal) {
      $res.StatusCode = 403
    } elseif ($null -eq $entry -or -not (Test-Path (Join-Path $root $entry[0]))) {
      $res.StatusCode = 404
    } else {
      $bytes = [System.IO.File]::ReadAllBytes((Join-Path $root $entry[0]))
      $res.ContentType = $entry[1]
      $res.Headers.Add('Cache-Control', 'no-cache')
      $res.ContentLength64 = $bytes.Length
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
    }
  } catch {
    $res.StatusCode = 500
  } finally {
    $res.Close()
  }
}
$listener.Stop()
