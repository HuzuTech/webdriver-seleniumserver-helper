$process = Get-Process -ProcessName "java"
Write-Host $process.Id
