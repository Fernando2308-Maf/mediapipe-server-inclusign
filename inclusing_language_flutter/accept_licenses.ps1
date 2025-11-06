$env:JAVA_HOME = "C:\Java\jdk-17.0.2"
$env:ANDROID_HOME = "C:\Android"
$env:PATH = "$env:JAVA_HOME\bin;$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:ANDROID_HOME\platform-tools;$env:PATH"

Write-Host "Aceptando licencias de Android..." -ForegroundColor Cyan

$licenses = flutter doctor --android-licenses 2>&1
if ($licenses -match "All SDK package licenses accepted") {
    Write-Host "Licencias ya aceptadas" -ForegroundColor Green
} else {
    Write-Host "Ejecutando flutter doctor --android-licenses con 'y' automatico..." -ForegroundColor Yellow

    # Crear un proceso que automáticamente responda 'y'
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "flutter"
    $psi.Arguments = "doctor --android-licenses"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    $process.Start() | Out-Null

    # Enviar 'y' 10 veces (para todas las licencias)
    for ($i = 0; $i -lt 10; $i++) {
        $process.StandardInput.WriteLine("y")
        Start-Sleep -Milliseconds 500
    }

    $process.WaitForExit()
    $output = $process.StandardOutput.ReadToEnd()
    $error = $process.StandardError.ReadToEnd()

    Write-Host $output
    Write-Host $error -ForegroundColor Red
}

Write-Host "`nListo! Ahora puedes ejecutar: flutter run" -ForegroundColor Green
