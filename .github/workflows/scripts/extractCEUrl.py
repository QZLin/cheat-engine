import re
import typing
from os import getcwd, path

filepath = path.join(path.abspath(getcwd()), "embedded/CompiledCode.bin")

with open(filepath, "r") as f:
  data = f.read()
  data = re.sub(r"[^a-zA-Z0-9.:/\n\r]", "", data)
  match = typing.cast(
    re.Match[str],
    re.search(
      r"(?P<url>https:\/\/[a-zA-Z0-9]+\.cloudfront.net\/f\/CheatEngine\/[0-9]+\/CheatEngine[0-9]*\.exe)(?P<silent>\/[A-Z]+)?(?P<dist>\/[A-Z]+)?",
      data))

filepath = path.join(path.abspath(getcwd()), "InstallCE.bat")

with open(filepath, "w") as f:
  f.write(r"""@ECHO OFF

cd /d %~dp0\..\..\..\

.\CheatEngineExtracted.exe {} {}

:waitloop
TASKLIST |find.exe /I "CheatEngineExtracted.exe" >NUL
IF ERRORLEVEL 1 GOTO endloop
timeout /t 1 /nobreak>NUL
goto waitloop
:endloop
""".format(match.group("silent") or " ",
           match.group("dist") or " "))

print(match.group("url"))
