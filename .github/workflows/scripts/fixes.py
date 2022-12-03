import typing
from xml.etree.ElementTree import Element, SubElement, parse
from os import getcwd, path

#region missing virtualtreeview_package
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

#endregion

#region doubletoextended fix
filepath = path.join(path.abspath(getcwd()),
                     "Cheat Engine/frmModifyRegistersUnit.pas")

with open(filepath, "r") as f:
  data = f.read()
  data = data.replace(
    """              if reg^.size=10 then doubletoextended(@d, reg^.getPointer(regeditinfo.context)) else
              if reg^.size=4 then copymemory(reg^.getPointer(regeditinfo.context),@f,sizeof(f)) else
              if reg^.size=8 then copymemory(reg^.getPointer(regeditinfo.context),@d,sizeof(d))""",
    """              {$ifdef cpux86_64}
              if reg^.size=10 then doubletoextended(@d, reg^.getPointer(regeditinfo.context)) else
              {$else}
              if reg^.size=10 then copymemory(reg^.getPointer(regeditinfo.context),@d,10) else
              {$endif}
              if reg^.size=4 then copymemory(reg^.getPointer(regeditinfo.context),@f,sizeof(f)) else
              if reg^.size=8 then copymemory(reg^.getPointer(regeditinfo.context),@d,sizeof(d))"""
  )

with open(filepath, "w") as f:
  f.write(data)
#endregion
