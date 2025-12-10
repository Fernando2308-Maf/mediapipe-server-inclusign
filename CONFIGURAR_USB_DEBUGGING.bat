@echo off
echo ============================================================
echo   CONFIGURACION USB DEBUGGING - Inclusign
echo ============================================================
echo.

echo [1/5] Verificando dispositivos conectados...
flutter doctor --android-licenses > nul 2>&1
C:\src\flutter\bin\cache\dart-sdk\..\..\..\platform-tools\adb.exe devices
if errorlevel 1 (
    echo.
    echo ERROR: No se encontro ADB o no hay dispositivos conectados
    echo.
    echo SOLUCION:
    echo 1. Conecta tu celular por USB
    echo 2. Habilita "Depuracion USB" en Opciones de desarrollador
    echo 3. Acepta el dialogo de autorizacion en el celular
    echo.
    pause
    exit /b 1
)

echo.
echo [2/5] Configurando mapeo de puertos (adb reverse)...
echo Mapeando puerto 5000 (MediaPipe Server)...
C:\src\flutter\bin\cache\dart-sdk\..\..\..\platform-tools\adb.exe reverse tcp:5000 tcp:5000

echo.
echo [3/5] Verificando servidor MediaPipe...
curl -s http://localhost:5000/health
if errorlevel 1 (
    echo.
    echo ADVERTENCIA: El servidor MediaPipe no esta corriendo
    echo.
    echo SOLUCION: Inicia el servidor con:
    echo   INICIAR_MEDIAPIPE_SERVER.bat
    echo.
)

echo.
echo [4/5] Verificando Django API...
echo Consultando: https://django-rest-framework-1.onrender.com
curl -s -o nul -w "Status HTTP: %%{http_code}\n" https://django-rest-framework-1.onrender.com

echo.
echo [5/5] Configuracion completada!
echo.
echo ============================================================
echo   SIGUIENTE PASO: Ejecutar la app en el dispositivo
echo ============================================================
echo.
echo Comando para ejecutar:
echo   cd inclusing_language_flutter
echo   flutter run
echo.
echo El celular podra acceder a:
echo   - MediaPipe Server: http://10.0.2.2:5000
echo   - Django API: https://django-rest-framework-1.onrender.com
echo.
echo ============================================================
pause
