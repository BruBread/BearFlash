@echo off
setlocal EnableExtensions
rem Portable Go toolchain installer. Downloads the latest stable Go SDK and extracts it to .\go\ next to
rem this script (so .\go\bin\go.exe exists). Run manually; needs internet once. Not wired to autorun.
set "DEST=%~dp0"
echo Downloading the latest Go SDK (one time, ~75 MB)...
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $v=((Invoke-RestMethod 'https://go.dev/dl/?mode=json') | Where-Object stable | Select-Object -First 1).version; $url='https://go.dev/dl/'+$v+'.windows-amd64.zip'; $zip=Join-Path $env:TEMP ($v+'.zip'); Write-Host ('Version '+$v); Invoke-WebRequest $url -OutFile $zip; if (Test-Path '%DEST%go') { Remove-Item '%DEST%go' -Recurse -Force }; Write-Host 'Extracting...'; Expand-Archive $zip -DestinationPath '%DEST%' -Force; Remove-Item $zip -Force"
if exist "%~dp0go\bin\go.exe" (
    echo.
    "%~dp0go\bin\go.exe" version
    echo Installed to %~dp0go
) else (
    echo Install failed: go\bin\go.exe not found.
)
pause
