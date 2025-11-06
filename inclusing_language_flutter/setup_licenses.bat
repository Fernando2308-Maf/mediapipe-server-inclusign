@echo off
echo ========================================
echo Configurando Android SDK
echo ========================================
echo.

set JAVA_HOME=C:\Java\jdk-17.0.2
set ANDROID_HOME=C:\Android
set PATH=%JAVA_HOME%\bin;%ANDROID_HOME%\cmdline-tools\latest\bin;%ANDROID_HOME%\platform-tools;%PATH%

echo Instalando paquetes de Android SDK...
echo.

call sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

echo.
echo ========================================
echo Aceptando licencias de Android
echo ========================================
echo.
echo Por favor, escribe 'y' y presiona Enter para cada licencia
echo.

call flutter doctor --android-licenses

echo.
echo ========================================
echo Configuracion completada!
echo ========================================
echo.
echo Ahora puedes ejecutar: run_android.bat
echo.

pause
