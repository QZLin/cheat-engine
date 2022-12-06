@ECHO OFF

cd /d %~dp0\..\..\..\

.\DXSDK_Jun10.exe /U

:waitloop
TASKLIST |find.exe /I "DXSDK_Jun10.exe" >NUL
IF ERRORLEVEL 1 GOTO endloop
timeout /t 1 /nobreak>NUL
goto waitloop
:endloop
