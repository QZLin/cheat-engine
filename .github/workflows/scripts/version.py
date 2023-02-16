from typing import cast
from xml.etree.ElementTree import Element, parse
from os import getcwd, path, environ
from datetime import datetime

cwd = path.abspath(getcwd())

filepath = path.join(cwd, "Cheat Engine/cheatengine.lpi")

tree = parse(filepath)
root = tree.getroot()
versionInfo = cast(Element, root.find("ProjectOptions/VersionInfo"))

try:
  major = cast(Element, versionInfo.find("MajorVersionNr")).get("Value")
except AttributeError:
  major = 0
try:
  minor = cast(Element, versionInfo.find("MinorVersionNr")).get("Value")
except AttributeError:
  minor = 0
try:
  revision = cast(Element, versionInfo.find("RevisionNr")).get("Value")
except AttributeError:
  revision = 0
try:
  build = cast(Element, versionInfo.find("BuildNr")).get("Value")
except AttributeError:
  build = 0

isotime = datetime.utcnow().isoformat(timespec="milliseconds")
time = datetime.now(None).isoformat(" ", "minutes")

with open(cast(str, environ.get("GITHUB_OUTPUT")), "a") as output:
  output.writelines([
    f"\nmajor={major}",  #
    f"\nminor={minor}",  #
    f"\nrevision={revision}",  #
    f"\nbuild={build}",  #
    f"\nisotime={isotime}",  #
    f"\ntime={time}"
  ])
