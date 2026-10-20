@echo off
rem Start the local server (if not running) and open the app
powershell -NoProfile -Command "try{(New-Object Net.Sockets.TcpClient('127.0.0.1',5179)).Close();exit 0}catch{exit 1}"
if errorlevel 1 (
  start "" powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0server.ps1"
  timeout /t 2 /nobreak >nul
)
start "" http://localhost:5179/
