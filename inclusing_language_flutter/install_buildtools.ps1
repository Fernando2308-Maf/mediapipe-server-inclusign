$env:JAVA_HOME = "C:\Java\jdk-17.0.2"
$env:ANDROID_HOME = "C:\Android"
$env:PATH = "$env:JAVA_HOME\bin;$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:ANDROID_HOME\platform-tools;$env:PATH"

Write-Host "Instalando Android build-tools..." -ForegroundColor Cyan
Write-Host ""

& "$env:ANDROID_HOME\cmdline-tools\latest\bin\sdkmanager.bat" "build-tools;34.0.0"

Write-Host ""
Write-Host "Build-tools instalado!" -ForegroundColor Green
