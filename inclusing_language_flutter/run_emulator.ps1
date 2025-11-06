$env:JAVA_HOME = "C:\Java\jdk-17.0.2"
$env:ANDROID_HOME = "C:\Android"
$env:PATH = "$env:JAVA_HOME\bin;$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:ANDROID_HOME\platform-tools;$env:ANDROID_HOME\emulator;$env:PATH"

Write-Host "Variables de entorno configuradas:" -ForegroundColor Cyan
Write-Host "JAVA_HOME: $env:JAVA_HOME" -ForegroundColor Gray
Write-Host "ANDROID_HOME: $env:ANDROID_HOME" -ForegroundColor Gray
Write-Host ""

Write-Host "Iniciando emulador de Android..." -ForegroundColor Green
Write-Host "Esto puede tardar unos minutos la primera vez..." -ForegroundColor Yellow
Write-Host ""

# Iniciar emulador en background
Start-Process -FilePath "$env:ANDROID_HOME\emulator\emulator.exe" -ArgumentList "-avd", "flutter_emulator", "-no-snapshot-load" -WindowStyle Normal

Write-Host "Esperando que el emulador inicie..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host ""
Write-Host "Ejecutando Flutter en el emulador..." -ForegroundColor Green
Write-Host ""

flutter run
