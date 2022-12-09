@ECHO OFF

cd /d %~dp0\..\..\..\

.\ndp472-devpack-enu.exe /quiet /norestart

:waitloop
TASKLIST |find.exe /I "ndp472-devpack-enu.exe" >NUL
IF ERRORLEVEL 1 GOTO endloop
timeout /t 1 /nobreak>NUL
goto waitloop
:endloop
