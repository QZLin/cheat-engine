from typing import cast
from xml.etree.ElementTree import Element, SubElement, parse
from os import getcwd, path
from glob import glob
from re import sub

cwd = path.abspath(getcwd())

#region missing virtualtreeview_package

filepath = path.join(cwd, "Cheat Engine/Tutorial/tutorial.lpi")

tree = parse(filepath)
root = tree.getroot()
requiredPackages = cast(Element, root.find("ProjectOptions/RequiredPackages"))
virtualtreeview_package = requiredPackages.find(
  '*/PackageName[@Value="laz.virtualtreeview_package"]')

if (virtualtreeview_package == None):
  number = str(int(cast(str, requiredPackages.get("Count"))) + 1)
  requiredPackages.set("Count", number)
  packageItem = SubElement(requiredPackages, "Item" + number)
  package = SubElement(packageItem, "PackageName")
  package.set("Value", "laz.virtualtreeview_package")
  tree.write(filepath, encoding="utf8")

#endregion

#region doubletoextended fix
# filepath = path.join(cwd, "Cheat Engine/frmModifyRegistersUnit.pas")

# with open(filepath, "r") as f:
#   data = f.read()
#   data = data.replace(
#     """              if reg^.size=10 then doubletoextended(@d, reg^.getPointer(regeditinfo.context)) else
#               if reg^.size=4 then copymemory(reg^.getPointer(regeditinfo.context),@f,sizeof(f)) else
#               if reg^.size=8 then copymemory(reg^.getPointer(regeditinfo.context),@d,sizeof(d))""",
#     """              {$ifdef cpux86_64}
#               if reg^.size=10 then doubletoextended(@d, reg^.getPointer(regeditinfo.context)) else
#               {$else}
#               if reg^.size=10 then copymemory(reg^.getPointer(regeditinfo.context),@d,10) else
#               {$endif}
#               if reg^.size=4 then copymemory(reg^.getPointer(regeditinfo.context),@f,sizeof(f)) else
#               if reg^.size=8 then copymemory(reg^.getPointer(regeditinfo.context),@d,sizeof(d))"""
#   )

# with open(filepath, "w") as f:
#   f.write(data)
#endregion


#region Direct x mess fix
def dxN(filepath):
  with open(filepath, "r") as f:
    data = f.read()
    data = data.replace(
      """      <DebugInformationFormat>ProgramDatabase</DebugInformationFormat>
    </ClCompile>""",
      r"""      <DebugInformationFormat>ProgramDatabase</DebugInformationFormat>
      <AdditionalIncludeDirectories>C:\Program Files (x86)\Microsoft DirectX SDK (June 2010)\Include</AdditionalIncludeDirectories>
    </ClCompile>""")
    data = data.replace(
      "<AdditionalDependencies>d3d",
      r"<AdditionalDependencies>C:\Program Files (x86)\Microsoft DirectX SDK (June 2010)\Lib\x86\d3d",
      1)
    data = data.replace(
      "<AdditionalDependencies>d3d",
      r"<AdditionalDependencies>C:\Program Files (x86)\Microsoft DirectX SDK (June 2010)\Lib\x64\d3d",
      1)
    data = data.replace(
      "<AdditionalDependencies>d3d",
      r"<AdditionalDependencies>C:\Program Files (x86)\Microsoft DirectX SDK (June 2010)\Lib\x86\d3d",
      1)
    data = data.replace(
      "<AdditionalDependencies>d3d",
      r"<AdditionalDependencies>C:\Program Files (x86)\Microsoft DirectX SDK (June 2010)\Lib\x64\d3d",
      1)

  with open(filepath, "w") as f:
    f.write(data)


dx9ProjPath = path.join(
  cwd, "Cheat Engine/Direct x mess/CED3D9Hook/CED3D9Hook.vcxproj")
dx10ProjPath = path.join(
  cwd, "Cheat Engine/Direct x mess/CED3D10Hook/CED3D10Hook.vcxproj")
dx11ProjPath = path.join(
  cwd, "Cheat Engine/Direct x mess/CED3D11Hook/CED3D11Hook.vcxproj")
dxBaseProjPath = path.join(
  cwd, "Cheat Engine/Direct x mess/DXHookBase/DXHookBase.vcxproj")
dxBaseCppPath = path.join(
  cwd, "Cheat Engine/Direct x mess/DXHookBase/DXHookBase.cpp")

dxN(dx9ProjPath)
dxN(dx10ProjPath)
dxN(dx11ProjPath)
dxN(dxBaseProjPath)

with open(dxBaseCppPath, "r") as f:
  data = f.read()
  data = data.replace("D3D_FEATURE_LEVEL_11_1", r"0xb100")

with open(dxBaseCppPath, "w") as f:
  f.write(data)
#endregion

#region MonoDataCollector fix
# filepath = path.join(
#   cwd,
#   "Cheat Engine/MonoDataCollector/MonoDataCollector/MonoDataCollector.vcxproj")

# with open(filepath, "r") as f:
#   data = f.read()
#   data = data.replace("Unicode", "Multibyte")

# with open(filepath, "w") as f:
#   f.write(data)

# filepath = path.join(
#   cwd, "Cheat Engine/MonoDataCollector/MonoDataCollector/PipeServer.cpp")

# with open(filepath, "r") as f:
#   data = f.read()
#   data = data.replace('GetModuleHandle(L"mono.dll")',
#                       'GetModuleHandle("mono.dll")')
# """
#   data = data.replace("#ifndef WINDOWS", "#ifndef _WINDOWS")
#   data = data.replace(
#     'OutputDebugString("CPipeServer::ConnectThreadToMonoRuntime()',
#     '//OutputDebugString("CPipeServer::ConnectThreadToMonoRuntime()')
# """

# with open(filepath, "w") as f:
#   f.write(data)
#endregion

#region DotNetDataCollector fix
"""
filepath = path.join(
  cwd,
  "Cheat Engine/DotNetDataCollector/DotNetDataCollector/DotNetDataCollector.vcxproj"
)

with open(filepath, "r") as f:
  data = f.read()
  data = data.replace("4.7.2", "4.8.1")

with open(filepath, "w") as f:
  f.write(data)
"""
#endregion

#region cepack fix
fileglob = path.join(cwd, "Cheat Engine/ceregreset/*.res")
filepath = path.join(cwd, "Cheat Engine/ceregreset/ceregreset.dpr")
files = glob(fileglob)
if (len(files) == 0):
  with open(filepath, "r") as f:
    data = f.read()
    data = data.replace("{$R *.res}", "")

  with open(filepath, "w") as f:
    f.write(data)
#endregion

#region GetThreadName fix
# filepath = path.join(cwd, "Cheat Engine/guisafecriticalsection.pas")

# with open(filepath, "r") as f:
#   data = f.read()
#   data = data.replace("+GetThreadName(lockedthreadid)+", "+")

# with open(filepath, "w") as f:
#   f.write(data)
#endregion

#region forgotten semicolon fix
# filepath = path.join(cwd, "Cheat Engine/frmautoinjectunit.pas")
# with open(filepath, "r") as f:
#   data = f.read()
#   data = sub(r"commapos:=d\.LastDisassembleData\.parameters\.IndexOf\(','\)(?=[^;])", "commapos:=d.LastDisassembleData.parameters.IndexOf(',');", data)

# with open(filepath, "w") as f:
#   f.write(data)
#endregion


#region undefined offset value
# filepath = path.join(cwd, "Cheat Engine/LuaByteTable.pas")
# with open(filepath, "r") as f:
#   data = f.read()
#   if (data.count("offset") == 1):
#     data = data.replace("offset", "tablestartindex")

#     with open(filepath, "w") as f:
#       f.write(data)
#endregion
