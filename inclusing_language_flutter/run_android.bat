@echo off
echo Configurando variables de entorno para Android...

set JAVA_HOME=C:\Java\jdk-17.0.2
set ANDROID_HOME=C:\Android
set PATH=%JAVA_HOME%\bin;%ANDROID_HOME%\cmdline-tools\latest\bin;%ANDROID_HOME%\platform-tools;%PATH%

echo.
echo JAVA_HOME: %JAVA_HOME%
echo ANDROID_HOME: %ANDROID_HOME%
echo.
echo Ejecutando Flutter en Android...
echo.

flutter run

pause
