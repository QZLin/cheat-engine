@ECHO OFF

cd /d %~dp0\..\..\..\vs

.\wdexpress_full.exe /Quiet /NoRestart

:waitloop
TASKLIST |find.exe /I "wdexpress_full.exe" >NUL
IF ERRORLEVEL 1 GOTO endloop
timeout /t 1 /nobreak>NUL
goto waitloop
:endloop

cd ..
