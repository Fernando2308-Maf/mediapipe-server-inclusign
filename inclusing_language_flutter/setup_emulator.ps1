$env:JAVA_HOME = "C:\Java\jdk-17.0.2"
$env:ANDROID_HOME = "C:\Android"
$env:PATH = "$env:JAVA_HOME\bin;$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:ANDROID_HOME\platform-tools;$env:ANDROID_HOME\emulator;$env:PATH"

Write-Host "Configurando emulador de Android..." -ForegroundColor Cyan
Write-Host ""

# Instalar emulador y system image
Write-Host "Instalando emulador y system image..." -ForegroundColor Yellow
& "$env:ANDROID_HOME\cmdline-tools\latest\bin\sdkmanager.bat" "emulator" "system-images;android-33;google_apis;x86_64"

Write-Host ""
Write-Host "Creando Android Virtual Device (AVD)..." -ForegroundColor Yellow

# Crear AVD
echo "no" | & "$env:ANDROID_HOME\cmdline-tools\latest\bin\avdmanager.bat" create avd -n flutter_emulator -k "system-images;android-33;google_apis;x86_64" --force

Write-Host ""
Write-Host "Emulador configurado!" -ForegroundColor Green
Write-Host "Para iniciar el emulador, ejecuta: run_emulator.ps1" -ForegroundColor Cyan
