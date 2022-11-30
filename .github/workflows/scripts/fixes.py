import typing
from xml.etree.ElementTree import Element, SubElement, parse, tostring
from os import getcwd, path
import os

filepath = path.join(path.abspath(getcwd()), "Cheat Engine/cheatengine.lpi")

tree = parse(filepath)
root = tree.getroot()
requiredPackages = typing.cast(Element,
                               root.find("ProjectOptions/RequiredPackages"))
virtualtreeview_package = requiredPackages.find(
  '*/PackageName[@Value="laz.virtualtreeview_package"]')

if (virtualtreeview_package == None):
  number = str(int(typing.cast(str, requiredPackages.get("Count"))) + 1)
  requiredPackages.set("Count", number)
  packageItem = SubElement(requiredPackages, "Item" + number)
  package = SubElement(packageItem, "PackageName")
  package.set("Value", "laz.virtualtreeview_package")
  tree.write(filepath, encoding="utf8")
