@ECHO OFF

cd /d %~dp0\..\..\..\

.\ndp461-devpack-kb3105179-enu.exe /quiet /norestart

:waitloop
TASKLIST |find.exe /I "ndp461-devpack-kb3105179-enu.exe" >NUL
IF ERRORLEVEL 1 GOTO endloop
timeout /t 1 /nobreak>NUL
goto waitloop
:endloop
