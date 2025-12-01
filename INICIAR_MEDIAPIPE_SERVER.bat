@echo off
echo ================================================================
echo  INCLUSIGN - Servidor MediaPipe para Reconocimiento de Gestos
echo ================================================================
echo.
echo Iniciando servidor MediaPipe en http://localhost:5000
echo Presiona Ctrl+C para detener el servidor
echo.
echo ================================================================
echo.

cd "Proyecto integrador - copia\Proyecto integrador - copia"

REM Activar el entorno virtual
call .venv\Scripts\activate.bat

REM Iniciar el servidor MediaPipe
python mediapipe_server.py

pause
