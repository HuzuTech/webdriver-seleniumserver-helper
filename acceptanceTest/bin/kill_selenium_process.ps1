$process = Get-Process -ProcessName "java"
Stop-Process $process.Id