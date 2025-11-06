$env:JAVA_HOME = "C:\Java\jdk-17.0.2"
$env:ANDROID_HOME = "C:\Android"
$env:PATH = "$env:JAVA_HOME\bin;$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:ANDROID_HOME\platform-tools;$env:PATH"

Write-Host "Variables de entorno configuradas:" -ForegroundColor Cyan
Write-Host "JAVA_HOME: $env:JAVA_HOME" -ForegroundColor Gray
Write-Host "ANDROID_HOME: $env:ANDROID_HOME" -ForegroundColor Gray
Write-Host ""
Write-Host "Ejecutando Flutter en Samsung Galaxy S20+..." -ForegroundColor Green
Write-Host ""

flutter run -d "SM G986U"
