if getTranslationFolder()~='' then
  loadPOFile(getTranslationFolder()..'Java.po')
end

--todo: split up into multiple units and use the java table for the methods as well
--especially strip the hotspot stuff to it's own file



JAVACMD_STARTCODECALLBACKS=0
JAVACMD_STOPCODECALLBACKS=1
JAVACMD_GETLOADEDCLASSES=2
JAVACMD_DEREFERENCELOCALOBJECT=3
JAVACMD_GETCLASSMETHODS=4
JAVACMD_GETCLASSFIELDS=5
JAVACMD_GETIMPLEMENTEDINTERFACES=6
JAVACMD_FINDREFERENCESTOOBJECT=7
JAVACMD_FINDJOBJECT=8
JAVACMD_GETCLASSSIGNATURE=9  --=getClassName
JAVACMD_GETSUPERCLASS=10
JAVACMD_GETOBJECTCLASS=11
JAVACMD_GETCLASSDATA=12
JAVACMD_REDEFINECLASS=13
JAVACMD_FINDCLASS=14
JAVACMD_GETCAPABILITIES=15
JAVACMD_GETMETHODNAME=16 --gets the methodname and the signature
JAVACMD_INVOKEMETHOD=17
JAVACMD_FINDCLASSINSTANCES=18 --find objects that belong to the given class
JAVACMD_ADDTOBOOTSTRAPCLASSLOADERPATH=19
JAVACMD_ADDTOSYSTEMCLASSLOADERPATH=20
JAVACMD_PUSHLOCALFRAME=21
JAVACMD_POPLOCALFRAME=22
JAVACMD_GETFIELDDECLARINGCLASS=23
JAVACMD_GETFIELDSIGNATURE=24
JAVACMD_GETFIELD=25
JAVACMD_SETFIELD=26

JAVACMD_STARTSCAN=27
JAVACMD_REFINESCANRESULTS=28
JAVACMD_GETSCANRESULTS=29
JAVACMD_FINDWHATWRITES=30
JAVACMD_STOPFINDWHATWRITES=31
JAVACMD_GETMETHODDECLARINGCLASS=32
JAVACMD_RELEASECLASSLIST=33
JAVACMD_COMPILEMETHOD=34

JAVACMD_DEREFERENCEGLOBALOBJECTS=35
JAVACMD_GETFIELDVALUES=36
JAVACMD_COLLECTGARBAGE=37

JAVACMD_ANDROID_DECODEOBJECT=38
JAVACMD_FINDFIELDS=39
JAVACMD_FINDMETHODS=40
JAVAVMD_GETOBJECTCLASSNAME=41 --gets the name of the class instead of just a local ref
JAVACMD_SETFIELDVALUES=42


JAVACMD_TERMINATESERVER=255



JAVACODECMD_METHODLOAD=0
JAVACODECMD_METHODUNLOAD=1
JAVACODECMD_DYNAMICCODEGENERATED=2
JAVACODECMD_TERMINATED=255



JAVA_TIMEOUT=5000 --5 seconds

ACC_STATIC=8



function getFieldFromType(type, field, infloopprotection)
  if type==nil then return nil end

  if infloopprotection==nil then
  infloopprotection=0
  else
    infloopprotection=infloopprotection+1
    if infloopprotection>20 then
      return nil
    end
  end

  type=type:gsub("<.->(.-)","<%1>") --replace the <xxx> part with <>
  local Struct=JavaStructs[type]

  if (Struct==nil) or (Struct[field]==nil) then
    return getFieldFromType(JavaTypes[type].Alternate, field, infloopprotection) --check the super type if that one has fields
  else
    return Struct[field]
  end

end

function getKlassFromObject(object)
  return readQword(object+getFieldFromType("oopDesc","_metadata._klass").Offset)+JavaTypes["oopDesc"].Size
end

function CollectJavaSymbolsNonInjected(thread)
  if thread~=nil then
    thread.name="CollectJavaSymbolsNonInjected"
  end

  JavaStructs={}
  JavaTypes={}

  local s,s2


  s=readPointer("jvm.gHotSpotVMStructs")
  if (s==nil) or (s==0) then
    return --invalid JVM
  end

  VMStructEntryTypeNameOffset=readInteger("jvm.gHotSpotVMStructEntryTypeNameOffset")
  VMStructEntryFieldNameOffset=readInteger("jvm.gHotSpotVMStructEntryFieldNameOffset")
  VMStructEntryTypestringOffset=readInteger("jvm.gHotSpotVMStructEntryTypestringOffset")
  VMStructEntryIsStaticOffset=readInteger("jvm.gHotSpotVMStructEntryIsStaticOffset")
  VMStructEntryOffsetOffset=readInteger("jvm.gHotSpotVMStructEntryOffsetOffset")
  VMStructEntryAddressOffset=readInteger("jvm.gHotSpotVMStructEntryAddressOffset")
  VMStructEntryArrayStride=readInteger("jvm.gHotSpotVMStructEntryArrayStride")







--[[
  const char* typeName;            // The type name containing the given field (example: "Klass")
  const char* fieldName;           // The field name within the type           (example: "_name")
  const char* Typestring;          // Quoted name of the type of this field (example: "Symbol*";
                                   // parsed in Java to ensure type correctness
  int32_t  isStatic;               // Indicates whether following field is an offset or an address
  uint64_t offset;                 // Offset of field within structure; only used for nonstatic fields
  void* address;                   // Address of field; only used for static fields
                                   // ("offset" can not be reused because of apparent SparcWorks compiler bug
                                   // in generation of initializer data)
--]]




  while readString(readQword(s+VMStructEntryTypeNameOffset))~=nil do
    local a,b,c,d;
    a=readString(readPointer(s+VMStructEntryTypeNameOffset),255)
    b=readString(readPointer(s+VMStructEntryFieldNameOffset),255)
    c=readString(readPointer(s+VMStructEntryTypestringOffset),255)

    d=readPointer(s+VMStructEntryIsStaticOffset)

    if a and b and c then
      if JavaStructs[a]==nil then
        JavaStructs[a]={}
      end

      JavaStructs[a][b]={}
      JavaStructs[a][b].Typestring=c

      if d==0 then
        JavaStructs[a][b].Offset=readPointer(s+VMStructEntryOffsetOffset)
      else
        JavaStructs[a][b].Address=readPointer(s+VMStructEntryAddressOffset)
      end



      --if d~=0 then
      --  print(a.."  -  "..b.."  -  "..c.."  :  "..string.format("%x  ( %x )",readPointer(s+VMStructEntryAddressOffset), readPointer(readPointer(s+VMStructEntryAddressOffset)) ))
      --else
      --  print(a.."  -  "..b.."  -  "..c.."  :  "..string.format("%x",readPointer(s+VMStructEntryOffsetOffset)))
      --end
    end
    s=s+VMStructEntryArrayStride
  end



  --print("--------------------------------------------------------------------------------")


  s2=readPointer("jvm.gHotSpotVMTypes")
  VMTypeEntryTypeNameOffset=readInteger("jvm.gHotSpotVMTypeEntryTypeNameOffset")
  VMTypeEntrySuperclassNameOffset=readInteger("jvm.gHotSpotVMTypeEntrySuperclassNameOffset")
  VMTypeEntryIsOopTypeOffset=readInteger("jvm.gHotSpotVMTypeEntryIsOopTypeOffset")
  VMTypeEntryIsIntegerTypeOffset=readInteger("jvm.gHotSpotVMTypeEntryIsIntegerTypeOffset")
  VMTypeEntryIsUnsignedOffset=readInteger("jvm.gHotSpotVMTypeEntryIsUnsignedOffset")
  VMTypeEntrySizeOffset=readInteger("jvm.gHotSpotVMTypeEntrySizeOffset")
  VMTypeEntryArrayStride=readInteger("jvm.gHotSpotVMTypeEntryArrayStride")





  while readString(readPointer(s2+VMTypeEntryTypeNameOffset))~=nil do
    local a,b,isInteger, isOop, size;
    a=readString(readPointer(s2+VMTypeEntryTypeNameOffset),255)
    b=readString(readPointer(s2+VMTypeEntrySuperclassNameOffset),255)


    isOop=readInteger(s2+VMTypeEntryIsOopTypeOffset)
    isInteger=readInteger(s2+VMTypeEntryIsIntegerTypeOffset)
    size=readInteger(s2+VMTypeEntrySizeOffset)


    if a then
      local _a,_b
      _a=a:gsub("<.->(.-)","<%1>")
      JavaTypes[_a]={}
      JavaTypes[_a].Size=size

      if b then
        _b=b:gsub("<.->(.-)","<%1>")
        JavaTypes[_a].Alternate=_b
      end

    end



    local r=''
    if a then
      r=r..a
    end

    if b then
      r=r.."  -  "..b
    end


    --print(r.."  (size="..size..")")
    s2=s2+VMTypeEntryArrayStride
  end


 -- print("-------------------------------------------------")
--[[
  s=readPointer("jvm.gHotSpotVMIntConstants")
  VMIntConstantEntryNameOffset=readInteger("jvm.gHotSpotVMIntConstantEntryNameOffset")
  VMIntConstantEntryValueOffset=readInteger("jvm.gHotSpotVMIntConstantEntryValueOffset")
  VMIntConstantEntryArrayStride=readInteger("jvm.gHotSpotVMIntConstantEntryArrayStride")


  while readString(readPointer(s+VMIntConstantEntryNameOffset))~=nil do
    local name,value
    name=readString(readPointer(s+VMIntConstantEntryNameOffset))
    value=readInteger(s+VMIntConstantEntryValueOffset)

    --print(name.."="..string.format("%x",value))

    s=s+VMIntConstantEntryArrayStride
  end

  --print("-------------------------------------------------")
  s=readPointer("jvm.gHotSpotVMLongConstants")
  VMLongConstantEntryNameOffset=readInteger("jvm.gHotSpotVMLongConstantEntryNameOffset")
  VMLongConstantEntryValueOffset=readInteger("jvm.gHotSpotVMLongConstantEntryValueOffset")
  VMLongConstantEntryArrayStride=readInteger("jvm.gHotSpotVMLongConstantEntryArrayStride")

  while readString(readPointer(s+VMLongConstantEntryNameOffset))~=nil do
    local name,value
    name=readString(readPointer(s+VMLongConstantEntryNameOffset))
    value=readQword(s+VMLongConstantEntryValueOffset)

    --print(name.."="..string.format("%x",value))

    s=s+VMLongConstantEntryArrayStride
  end


  --Fetch the interpreter functions
  local InterpreterFunctionList=getFieldFromType('AbstractInterpreter', '_code').Address
  local BufferOffset=getFieldFromType('StubQueue', '_stub_buffer').Offset
  local QueueEndOffset=getFieldFromType('StubQueue', '_queue_end').Offset

  local InterpreterCodeletSizeOffset=getFieldFromType('InterpreterCodelet', '_size').Offset
  local InterpreterCodeletDescriptionOffset=getFieldFromType('InterpreterCodelet', '_description').Offset
  local InterpreterCodeletHeaderSize=JavaTypes['InterpreterCodelet'].Size
  local InterpreterCodeletHeaderSizeAligned

  InterpreterCodeletHeaderSizeAligned=InterpreterCodeletHeaderSize

  if targetIs64Bit() then
    --increase InterpreterCodeletHeaderSizeAligned so it's dividable by 32
    if (InterpreterCodeletHeaderSizeAligned % 32)~=0 then
      InterpreterCodeletHeaderSizeAligned=(InterpreterCodeletHeaderSizeAligned+32) - (InterpreterCodeletHeaderSizeAligned % 32)
    end
  else
    --increase InterpreterCodeletHeaderSizeAligned so it's dividable by 16
    if (InterpreterCodeletHeaderSizeAligned % 16)~=0 then
      InterpreterCodeletHeaderSizeAligned=(InterpreterCodeletHeaderSizeAligned+16) - (InterpreterCodeletHeaderSizeAligned % 16)
    end
  end

  StubQueueAddress=readPointer(InterpreterFunctionList)
  BufferStart=readPointer(StubQueueAddress+BufferOffset)
  BufferEnd=BufferStart+readInteger(StubQueueAddress+QueueEndOffset)

  CurrentPos=BufferStart
  while (CurrentPos<BufferEnd) do
    local CodeletSize=readInteger(CurrentPos+InterpreterCodeletSizeOffset)
    local Description=readString(readInteger(CurrentPos+InterpreterCodeletDescriptionOffset))
    local Codestart=CurrentPos+InterpreterCodeletHeaderSizeAligned

    --print(string.format("%x = %s", Codestart, Description))

    JavaSymbols.addSymbol("","jInterpreter_"..Description,Codestart, CodeletSize-InterpreterCodeletHeaderSizeAligned)



    CurrentPos=CurrentPos+CodeletSize
  end

--]]
  JavaHotSpotFieldsLoaded=true
end

function javaOpenAgent()
  if javapipe and (java.attachedProcess==getOpenedProcessID()) then
    return true
  end
  
  if (JavaSymbols==nil) then
    JavaSymbols=createSymbolList()
  else
    JavaSymbols.clear()
  end    
  
  javapipe=connectToPipe('cejavadc_pid'.. getOpenedProcessID(),10000)
  
  if javapipe then
    java.capabilities=java_getCapabilities()
    java.attachedProcess=getOpenedProcessID()
  
    if javaInjectedProcesses==nil then
      javaInjectedProcesses={}
    end
    
    javaInjectedProcesses[getOpenedProcessID()]=true
    
    javapipe.OnTimeout=function()
      print("javapipe timeout")
    end
    
    javapipe.OnError=function()
      print("javapipe error")
    end
    
    
    
    return true
  end    
end

function javaInjectAgent()
  if (java~=nil) and (java.attachedProcess==getOpenedProcessID()) and (javapipe) then
    return true
  end
  
  if (JavaSymbols==nil) then
    JavaSymbols=createSymbolList()
  else
    JavaSymbols.clear()
  end  

  if (javapipe ~= nil) then
    javapipe.destroy()  --this will cause the pipe listener to destroy the java event server, which will stop the javaeventthread (so no need to wait for that)
    javapipe=nil
  end


  if true then --java.android then
    local errorstr
    if not inMainThread() then error('Only call javaInjectAgent from the main thread') end
    
    local waitform=createForm(false)
    waitform.Position=poScreenCenter
    waitform.OnCloseQuery=function() 
      getLuaEngine().show()
      _G.waitform=waitform
      print("It will take a while. But if you're sure, issue the command:")
      print("waitform.OnCloseQuery=nil")
      print("waitform.close()")
      print("-----")
      local status=readInteger("ceagentloadstatus")
      if status then
        printf("readInteger(\"ceagentloadstatus\")=%d (<0 = error, 0=loading, 1=active, 2=finished)",status)
      end
      return false
    end
    waitform.caption='Please wait'
    local lbl=createLabel(waitform)
    lbl.caption='Please wait while the process is being injected into'
    
    waitform.BorderWidth=8
    waitform.autosize=true
    
    waitform.OnShow=function()
      createThread(function(t)
        function injectAndroidAgent()
          local status=readInteger("ceagentloadstatus")
          local extra=createStringList()
          if targetIsAndroid() then
            extra.add('#define ANDROID')          
          end 
         
          
          if (status==nil) or (status<0) or (status==2) then
            if not fileExists(getAutorunPath()..'java/jvmti.h') and (findTableFile('include/jvmti.h')==nil) then
              local l=getInternet()
              local r=l.getURL('https://github.com/openjdk-mirror/jdk7u-jdk/raw/master/src/share/javavm/export/jvmti.h')

              local ss=createStringStream(r)
              local tf=createTableFile('include/jvmti.h')
              tf.DoNotSave=true
              tf.Stream.copyFrom(ss,0)
              ss.destroy()
              ss=nil
            end
          
            local spath=getAutorunPath()..'java/androidloadagent.CEA'
            local sl=createStringList()
            
            
            if sl.loadFromFile(spath)==false then
              errorstr='Failure reading '..spath
              return
            end
                        
            local injectagentscript=extra.text..'\n'..sl.Text
            sl.destroy()
          
            local r,di=autoAssemble(injectagentscript);
            if not r then
              errorstr='Failure assembling inject script: '..di 
              return            
            end      
          end
          
          local start=getTickCount()
          
          while (readInteger("ceagentloadstatus")==0) or (getTickCount()-start>5000) do
            sleep(50);      
          end
          
          --printf("took: %d ms", getTickCount()-start)
          
          if readInteger("ceagentloadstatus")<1 then --1 when active, 2 when closed (e.g another server running)
            errorstr='Failure executing inject script: '..readInteger("ceagentloadstatus")            
            return
          end 
        end

        injectAndroidAgent()

        t.synchronize(function()
          if waitform then
            waitform.OnCloseQuery=nil
            waitform.close()
          end
        end)
      end)        
    end
    waitform.showModal()
    
    if errorstr then     
      return nil, errorstr
    end

       
    return javaOpenAgent()
  end
  
  printf("old code reached")
  if true then return end
  

  createNativeThread(CollectJavaSymbolsNonInjected)


  local alreadyinjected=false

  
  if javaInjectedProcesses==nil then
    javaInjectedProcesses={}

    if not java.android then
      local address=getAddressSafe('CEJVMTI.dll')
      if (address~=nil) and (address~=0) then
        javaInjectedProcesses[getOpenedProcessID()]=true
        alreadyinjected=true
        --opened a process with the JVMTI agent already running
      end
    end;

  else
    --check if already injected
    alreadyinjected=javaInjectedProcesses[getOpenedProcessID()]==true
  end
  



  local dllpath

  if targetIs64Bit() then
    dllpath=getCheatEngineDir()..[[autorun\dlls\64\CEJVMTI]]
  else
    dllpath=getCheatEngineDir()..[[autorun\dlls\32\CEJVMTI]]
  end



  if (alreadyinjected==false) then
    local script=''

    if targetIs64Bit() then  
      script=[[
        globalalloc(bla,1024)

        globalalloc(cmd,16)
        globalalloc(arg0,256)
        globalalloc(arg1,256)
        globalalloc(arg2,256)
        globalalloc(result,4)

        globalalloc(pipename,256)

        cmd:
        db 'load',0

        arg0:

        db ']]..dllpath..[[',0

        arg1:
        db 0

        arg2:
        db 0

        pipename:
        db '\\.\pipe\cejavapipe',0


        bla:
        sub rsp,8
        sub rsp,30

        mov rcx,cmd
        mov rdx,arg0
        mov r8,arg1
        mov r9,arg2
        mov rax,pipename
                       
        mov [rsp],rcx
        mov [rsp+8],rdx
        mov [rsp+10],r8
        mov [rsp+18],r9
        mov [rsp+20],rax
        
        call jvm.JVM_EnqueueOperation
        mov [result],eax

        add rsp,38
        ret

        createthread(bla)
      ]]
    else
      script=[[
        globalalloc(bla,1024)

        globalalloc(cmd,16)
        globalalloc(arg0,256)
        globalalloc(arg1,256)
        globalalloc(arg2,256)
        globalalloc(result,4)

        globalalloc(pipename,256)

        cmd:
        db 'load',0

        arg0:

        db ']]..dllpath..[[',0

        arg1:
        db 0

        arg2:
        db 0

        pipename:
        db '\\.\pipe\cejavapipe',0


        bla:
        push pipename
        push arg2
        push arg1
        push arg0
        push cmd


        call jvm.JVM_EnqueueOperation
        mov [result],eax

        ret

        createthread(bla)
      ]]
    end
  if autoAssemble(script)==false then
    error(translate('Auto assembler failed:')..script)
  end


  javaInjectedProcesses[getOpenedProcessID()]=true
  end




  --wait till attached

  local timeout=getTickCount()+JAVA_TIMEOUT
  while (javapipe==nil) and (getTickCount()<timeout) do
    javapipe=connectToPipe('cejavadc_pid'..getOpenedProcessID())
  end

  if (javapipe==nil) then
    return 0 --failure
  end

  java_StartListeneningForEvents()

  JavaSymbols.register() --make these symbols available to all of cheat engine


  java.capabilities=java_getCapabilities()
  java.attachedProcess=getOpenedProcessID();

  return true;
end

function JavaEventListener(thread)
  if thread~=nil then
    thread.name="JavaEventListener"
  end

  --this code runs in another thread
  local EVENTCMD_METHODLOAD=0
  local EVENTCMD_METHODUNLOAD=1
  local EVENTCMD_DYNAMICCODEGENERATED=2
  local EVENTCMD_FIELDMODIFICATION=3

  local JavaEventPipe


  local timeout=getTickCount()+JAVA_TIMEOUT --5 seconds
  while (JavaEventPipe==nil) and (getTickCount()<timeout) do
    JavaEventPipe=connectToPipe('cejavaevents_pid'..getOpenedProcessID())
  end

  if (JavaEventPipe==nil) then
    return  --failure
  end


  while true do
    local command=JavaEventPipe.readByte()
  if command==EVENTCMD_METHODLOAD then  --methodload

    local size1, size2, size3,ssize,classname, methodname, methodsig

    local method=JavaEventPipe.readQword()
    local code_size=JavaEventPipe.readDword()
    local code_addr=JavaEventPipe.readQword()
    size1=JavaEventPipe.readWord()
    if (size1>0) then
      classname=JavaEventPipe.readString(size1)
    else
      classname=''
    end

    size2=JavaEventPipe.readWord()
    if (size2>0) then
      methodname=JavaEventPipe.readString(size2)
    else
      methodname=''
    end

    size3=JavaEventPipe.readWord()
    if (size3>0) then
        methodsig=JavaEventPipe.readString(size3)
    else
      methodsig=''
    end

    local endpos=classname:match'^.*();'
    if endpos~=nil then
        classname=string.sub(classname,1,endpos-1)
    end
    local name=classname.."::"..methodname..methodsig


    JavaSymbols.addSymbol("",classname.."::"..methodname,code_addr,code_size)

    --print(string.format("s1=%d s2=%d s3=%d  (cn=%s  mn=%s  ms=%s)", size1,size2,size3, classname, methodname, methodsig))

    --print(string.format("Methodload: %s -  (%x) %x-%x", name, method, code_addr, code_addr+code_size))


    --
  elseif command==EVENTCMD_METHODUNLOAD then --methodunload
    local method=JavaEventPipe.readQword()
    local code_addr=JavaEventPipe.readQword()

    print("EVENTCMD_METHODUNLOAD")
    JavaSymbols.deleteSymbol(code_addr)
    --
  elseif command==EVENTCMD_DYNAMICCODEGENERATED then --DynamicCodeGenerated
    local ssize
    local address=JavaEventPipe.readQword()
    local length=JavaEventPipe.readDword()
    ssize=JavaEventPipe.readWord()
    local name=JavaEventPipe.readString(ssize)

    --print(string.format("DynamicCode: %s  -  %x-%x", name, address, address+length))
    JavaSymbols.addSymbol("",name,address,length)


    --
  elseif command==EVENTCMD_FIELDMODIFICATION then

    --print("EVENTCMD_FIELDMODIFICATION")
    local id=JavaEventPipe.readDword()
    local entry={}

    --print("id=="..id)

    entry.methodid=JavaEventPipe.readQword()
    entry.location=JavaEventPipe.readQword()

    local stackcount=JavaEventPipe.readByte()
    local i
    local stack={}

    --print("stackcount=="..stackcount)

    for i=1, stackcount do
      stack[i]={}
      stack[i].methodid=JavaEventPipe.readQword()
      stack[i].location=JavaEventPipe.readQword()
    end

    entry.stack=stack



    if java.findwhatwriteslist~=nil then
    local fcd=java.findwhatwriteslist[id]

    if fcd~=nil then
      --check if this entry is already in the list
      local found=false

      for i=1, #fcd.entries  do
        if (fcd.entries[i].methodid==entry.methodid) and (fcd.entries[i].location==entry.location) then
          found=true
          break
        end
      end

      if not found then
        local mname=java_getMethodName(entry.methodid)

        local class=java_getMethodDeclaringClass(entry.methodid)
        local classname=java_getClassSignature(class)

        java_dereferenceLocalObject(class)

        entry.classname=classname
        entry.methodname=mname

        --execute this in the main thread (gui access)
        synchronize(function(classname, id, mname)
        local fcd=java.findwhatwriteslist[id]


        if fcd~=nil then --check that the found code dialog hasn't been freed while waiting for sync
          tventry=fcd.lv.items.add()
          tventry.Caption=classname

          tventry.SubItems.add(string.format('%x: %s', entry.methodid, mname))
          tventry.SubItems.add(entry.location)

          table.insert(fcd.entries, entry)
        end
      end, classname, id, mname)


      else
       -- print("Already in the list")
      end
    else
     -- print("fcd==nil")

    end
    else
     -- print("java.findwhatwriteslist==nil")
    end

    --print("done")
  elseif command==JAVACODECMD_TERMINATED then
    print(translate("Java:eventserver terminated"))
    break
  elseif command==nil then
    print(translate("Java:Disconnected"))
    break
    else
    print(translate("Java:Unexpected event received"))  --synchronize isn't necesary for print as that function is designed to synchronize internally
      break --unknown command
  end
  end

  print(translate("Java:Event handler terminating"))
  JavaEventPipe.destroy();
end

function java_getCapabilities()
  local result={}
  javapipe.lock()
  javapipe.writeByte(JAVACMD_GETCAPABILITIES)  
  local r=javapipe.readBytes(16)
  javapipe.unlock()
  
  local v=byteTableToQword(r) --only the first 40 bits are implemented atm
  
  local capabilityBitPositions={
     can_tag_objects = 0,
     can_generate_field_modification_events = 1,
     can_generate_field_access_events = 2,
     can_get_bytecodes = 3,
     can_get_synthetic_attribute = 4,
     can_get_owned_monitor_info = 5,
     can_get_current_contended_monitor = 6,
     can_get_monitor_info = 7,
     can_pop_frame = 8,
     can_redefine_classes = 9,
     can_signal_thread = 10,
     can_get_source_file_name = 11,
     can_get_line_numbers = 12,
     can_get_source_debug_extension = 13,
     can_access_local_variables = 14,
     can_maintain_original_method_order = 15,
     can_generate_single_step_events = 16,
     can_generate_exception_events = 17,
     can_generate_frame_pop_events = 18,
     can_generate_breakpoint_events = 19,
     can_suspend = 20,
     can_redefine_any_class = 21,
     can_get_current_thread_cpu_time = 22,
     can_get_thread_cpu_time = 23,
     can_generate_method_entry_events = 24,
     can_generate_method_exit_events = 25,
     can_generate_all_class_hook_events = 26,
     can_generate_compiled_method_load_events = 27,
     can_generate_monitor_events = 28,
     can_generate_vm_object_alloc_events = 29,
     can_generate_native_method_bind_events = 30,
     can_generate_garbage_collection_events = 31,
     can_generate_object_free_events = 32,
     can_force_early_return = 33,
     can_get_owned_monitor_stack_depth_info = 34,
     can_get_constant_pool = 35,
     can_set_native_method_prefix = 36,
     can_retransform_classes = 37,
     can_retransform_any_class = 38,
     can_generate_resource_exhaustion_heap_events = 39,
     can_generate_resource_exhaustion_threads_events = 40    
  }
  
  result.can_access_local_variables=v & (1<<capabilityBitPositions.can_access_local_variables) ~= 0
  result.can_generate_all_class_hook_events=v & (1<<capabilityBitPositions.can_generate_all_class_hook_events) ~= 0
  result.can_generate_breakpoint_events=v & (1<<capabilityBitPositions.can_generate_breakpoint_events) ~= 0
  result.can_generate_method_entry_events=v & (1<<capabilityBitPositions.can_generate_method_entry_events)~=0;
  result.can_generate_compiled_method_load_events=v & (1<<capabilityBitPositions.can_generate_compiled_method_load_events) ~= 0
  result.can_generate_field_access_events=v & (1<<capabilityBitPositions.can_generate_field_access_events) ~= 0
  result.can_generate_field_modification_events=v & (1<<capabilityBitPositions.can_generate_field_modification_events) ~= 0
  result.can_generate_single_step_events=v & (1<<capabilityBitPositions.can_generate_single_step_events) ~= 0
  result.can_get_bytecodes=v & (1<<capabilityBitPositions.can_get_bytecodes) ~= 0
  result.can_get_constant_pool=v & (1<<capabilityBitPositions.can_get_constant_pool) ~= 0
  result.can_maintain_original_method_order=v & (1<<capabilityBitPositions.can_maintain_original_method_order) ~= 0
  result.can_redefine_any_class=v & (1<<capabilityBitPositions.can_redefine_any_class) ~= 0
  result.can_redefine_classes=v & (1<<capabilityBitPositions.can_redefine_classes) ~= 0
  result.can_retransform_any_class=v & (1<<capabilityBitPositions.can_retransform_any_class) ~= 0
  result.can_retransform_classes=v & (1<<capabilityBitPositions.can_retransform_classes) ~= 0
  result.can_tag_objects=v & (1<<capabilityBitPositions.can_tag_objects) ~= 0



  return result,r;
end


function java_StartListeneningForEvents()
  javapipe.lock();
  javapipe.writeByte(JAVACMD_STARTCODECALLBACKS)


  --the javapipe will now be frozen until a javaeventpipe makes an connection
  createNativeThread(JavaEventListener);

  javapipe.unlock();
end

function java_getLoadedClasses()
  if javapipe==nil then return {} end
  local ms=createMemoryStream()
  javapipe.lock()
  javapipe.writeByte(JAVACMD_GETLOADEDCLASSES)

  local streamsize=javapipe.readDword()

  javapipe.readIntoStream(ms,streamsize);
  javapipe.unlock()


  ms.position=0;

  if ms.Size==0 then
    ms.destroy()
    return nil, 'java_getLoadedClasses failed'
  end

  local classcount=ms.readDword()
  local classes={}

  if classcount>0 then
    local i=0
    local length
    for i=1,classcount do
      classes[i]={}
      classes[i].jclass=ms.readQword()
      length=ms.readWord()
      classes[i].signature=ms.readString(length)

      length=ms.readWord()
      classes[i].generic=ms.readString(length)
      
      length=ms.readWord()
      if length>0 then
        classes[i].superclass_signature=ms.readString(length)
      end
      
      length=ms.readWord()
      if length>0 then
        classes[i].superclass_generic=ms.readString(length)
      end
    end

  end
  
  ms.destroy()
  
  table.sort(classes,function(a,b) return a.signature<b.signature end)  
  
  classes.jClassLookup={}
  classes.signatureLookup={}
  for i=1,#classes do
    classes.jClassLookup[classes[i].jclass]=classes[i] 
    classes.signatureLookup[classes[i].signature]=classes[i]
  end

  return classes
end

function java_pushLocalFrame(count)
  javapipe.lock()
  javapipe.writeByte(JAVACMD_PUSHLOCALFRAME)
  javapipe.writeWord(count)
  javapipe.unlock()
end

function java_popLocalFrame(result) --result can be nil
  local result=nil
  javapipe.lock()
  javapipe.writeByte(JAVACMD_POPLOCALFRAME)
  javapipe.writeQword(result)
  result=javapipe.readQword()
  javapipe.unlock()

  return result
end

function java_dereferenceLocalObject(object)
  javapipe.lock()
  javapipe.writeByte(JAVACMD_DEREFERENCELOCALOBJECT)
  javapipe.writeQword(object)
  javapipe.unlock()
end

function java_dereferenceGlobalObjects(objects)
  if objects==nil then return end
  
  if type(objects=='number') then
    --could be someone just passed one object mistakenly
    objects={objects}
  end
  
  local ms=createMemoryStream()
  ms.writeByte(JAVACMD_DEREFERENCEGLOBALOBJECTS)  
  ms.writeDword(#objects)
  for i=1,#objects do
    ms.writeQword(objects[i])    
  end

  ms.position=0  
  
  javapipe.lock()
  javapipe.writeFromStream(ms)
  javapipe.unlock()   

  ms.destroy()  
end

function java_cleanClasslist(classlist)
  local i
  for i=1, #classlist do
    java_dereferenceLocalObject(classlist[i].jclass)
  end
end

function java_compileMethod(method)
  javapipe.lock()
  javapipe.writeByte(JAVACMD_COMPILEMETHOD) 
  javapipe.writeQword(method)
  javapipe.unlock()
end

function java_getClassMethods(class)
  local ms=createMemoryStream()
  
  javapipe.lock()
  javapipe.writeByte(JAVACMD_GETCLASSMETHODS)
  javapipe.writeQword(class)
  local streamsize=javapipe.readDword()
  javapipe.readIntoStream(ms, streamsize);
  javapipe.unlock()
  ms.position=0;
  
  if ms.Size==0 then
    ms.destroy()
    return nil, 'java_getClassMethods failed'
  end   
  
  local count=ms.readDword()
  local i
  local result={}
  local length
  for i=1,count do
    result[i]={}
    result[i].jmethodid=ms.readQword()

    length=ms.readWord()
    result[i].name=ms.readString(length)

    length=ms.readWord()
    result[i].signature=ms.readString(length)

    length=ms.readWord()
    result[i].generic=ms.readString(length)
    
    result[i].modifiers=ms.readDword()
    result[i].static=(result[i].modifiers & ACC_STATIC)==ACC_STATIC
  end

  ms.destroy()
  
  table.sort(result,function(a,b) return a.name<b.name end)
  
  result.jmethodidLookup={}
  for i=1,#result do
    result.jmethodidLookup[result[i].jmethodid]=result[i]    
  end
  
  
  return result
end

function java_getClassFields(class)
  javapipe.lock()
  javapipe.writeByte(JAVACMD_GETCLASSFIELDS)
  javapipe.writeQword(class)
  local streamsize=javapipe.readDword()
  local ms=createMemoryStream()
  javapipe.readIntoStream(ms, streamsize);
  javapipe.unlock()
  ms.position=0;
  
  if ms.Size==0 then
    ms.destroy()
    return nil, 'java_getClassFields failed'
  end  

  local hasoffsets=false
  
  local count=ms.readDword()
  local i
  local result={}
  local staticresult={}
  local length
    
  for i=1,count do
    local e={}
    e.jfieldid=ms.readQword()

    length=ms.readWord()
    e.name=ms.readString(length)

    length=ms.readWord()
    e.signature=ms.readString(length)

    length=ms.readWord()
    e.generic=ms.readString(length)
    
    e.modifiers=ms.readDword()    
    e.offset=ms.readDword()
    
    if e.offset==0xffffffff then
      e.offset=nil
    else
      hasoffsets=true
    end
    
    e.static=(e.modifiers & ACC_STATIC)==ACC_STATIC; 

    if e.static then
      table.insert(staticresult,e)
    else
      table.insert(result,e)
    end
  end

  ms.destroy();
  
  if hasoffsets then
    table.sort(result,function(a,b) return (a.offset or -1)<(b.offset or -1) end)  
  else
    table.sort(result,function(a,b) return a.name<b.name end)
  end
  
  result.jfieldidLookup={}
  for i=1,#result do
    result.jfieldidLookup[result[i].jfieldid]=result[i]    
  end
  
  for i=1,#staticresult do
    result.jfieldidLookup[staticresult[i].jfieldid]=staticresult[i]    
  end
    
  
  return result,staticresult
end

--[[
function java_getAllClassFields(class)
  --get all the fields of the given class, including inherited ones

  --java_pushLocalFrame(16)

  local result={}
  while (class~=nil) and (class~=0) do
    local r=java_getClassFields(class)
    local i
    for i=1,#r do
      result[#result+1]=r[i]
    end

    class=java_getSuperClass(class) --this pushes an object on the local frame
  end

  --java_popLocalFrame(nil)

  return result

end--]]

function java_getImplementedInterfaces(class)
  result={}
  javapipe.lock()
  javapipe.writeByte(JAVACMD_GETIMPLEMENTEDINTERFACES)
  javapipe.writeQword(class)
  local count=javapipe.readDword()
  for i=1,count do
    result[i]=javapipe.readQword()
  end

  javapipe.unlock()
  return result
end



function java_findReferencesToObject(jObject)
  result={}
  local count=0
  javapipe.lock()
  javapipe.writeByte(JAVACMD_FINDREFERENCESTOOBJECT)
  javapipe.writeQword(jObject)

  count=javapipe.readDword()
  local i
  for i=1, count do
    result[i]=javapipe.readQword();
  end


  javapipe.unlock()

  return result
end


function java_redefineClassWithCustomData(class, memory)
  javapipe.lock()
  javapipe.writeByte(JAVACMD_REDEFINECLASS)
  javapipe.writeQword(class)
  javapipe.writeDword(#memory)
  javapipe.writeString(memory)
  javapipe.unlock()
end

function java_collectGarbage(class, memory)
  javapipe.lock()
  javapipe.writeByte(JAVACMD_COLLECTGARBAGE)
  javapipe.unlock()
end

function java_redefineClassWithCustomClassFile(class, filename)
  local f=assert(io.open(filename,"rb"))
  local data = f:read("*all")
  f:close()
  java_redefineClassWithCustomData(class, data)
end

function java_getClassData(class)
  --gets the .class binary data (tip: Write a .class parser/editor so you can modify attributes and method bodies)
  local result={}
  javapipe.lock()
  javapipe.writeByte(JAVACMD_GETCLASSDATA)
  javapipe.writeQword(class)

  result.size=javapipe.readDword()
  if (result.size > 0) then
    result.data=javapipe.readString(result.size)
  end
  javapipe.unlock()

  return result.data
end

function java_writeClassToDisk(class, filename)
  local data=java_getClassData(class)
  local f=assert(io.open(filename,"wb"))
  f:write(data)
  f:close()
end

function java_getMethodName(methodid)
  local name=nil
  local sig=nil
  local gen=nil

  javapipe.lock()
  javapipe.writeByte(JAVACMD_GETMETHODNAME)
  javapipe.writeQword(methodid)

  local length
  length=javapipe.readWord()
  name=javapipe.readString(length)

  length=javapipe.readWord()
  sig=javapipe.readString(length)

  length=javapipe.readWord()
  gen=javapipe.readString(length)

  javapipe.unlock()

  return name, sig, gen
end

function java_parseSignature_type(sig, i)
  local result=''
  local char=string.sub(sig,i,i)

  if (char=='V') or (char=='Z') or (char=='B') or (char=='C') or (char=='S') or (char=='I') or (char=='J') or (char=='F') or (char=='D') then
  result=char
  elseif char=='L' then
  local classtype
  local newi

  newi=string.find(sig,';', i+1)
  if newi==nil then
    return #sig --error
  end

  result=string.sub(sig, i, newi)

  i=newi
  elseif char=='[' then
  result,i=java_parseSignature_type(sig,i+1)
  result='['..result
  end

  return result,i

end


function java_parseSignature_method(sig, i, result)
  result.parameters={}

  while i<=#sig do
    local parem
    local char=string.sub(sig,i,i)

  --parse every type

  if char==')' then
    return i+1
  end

  param,i=java_parseSignature_type(sig, i)
  result.parameters[#result.parameters+1]=param
  i=i+1
  end
end

function java_parseSignature(sig)
  if sig==nil then
    error(translate('Invalid java signature'))
  end

  --parse the given signature
  local result={}
  local i=1
  while i<=#sig do
    local char=string.sub(sig,i,i)

  if char=='(' then
    i=java_parseSignature_method(sig, i+1, result)
  else
    if char~=' ' then
        result.returntype, i=java_parseSignature_type(sig, i)
    end

    i=i+1
  end
  end

  return result
end


Java_TypeSigToIDConversion={}
Java_TypeSigToIDConversion['V']=0 --void
Java_TypeSigToIDConversion['Z']=1 --boolean
Java_TypeSigToIDConversion['B']=2 --byte
Java_TypeSigToIDConversion['C']=3 --char
Java_TypeSigToIDConversion['S']=4 --short
Java_TypeSigToIDConversion['I']=5 --int
Java_TypeSigToIDConversion['J']=6 --long
Java_TypeSigToIDConversion['F']=7 --float
Java_TypeSigToIDConversion['D']=8 --double
Java_TypeSigToIDConversion['L']=9 --object
Java_TypeSigToIDConversion['[']=10 --array
 --11=string

function java_invokeMethod_sendParameter(typeid, a, skiptypeid)
  if (skiptypeid==nil) or (skiptypeid==true) then
    javapipe.writeByte(typeid)
  end

  if typeid==1 then --boolean
    if a==true then
      javapipe.writeByte(1)
  else
    javapipe.writeByte(0)
  end
  elseif typeid==2 then
    javapipe.writeByte(a)
  elseif typeid==3 then --char
    if tonumber(a)==nil then
    javapipe.writeWord(string.byte(a,1))
  else
      javapipe.writeWord(a)
  end

  elseif typeid==4 then --short
    javapipe.writeWord(a)
  elseif typeid==5 then --int
    javapipe.writeDword(a)
  elseif typeid==6 then --long
    javapipe.writeQword(a)
  elseif typeid==7 then --float
    javapipe.writeFloat(a)
  elseif typeid==8 then --double
    javapipe.writeDouble(a)
  elseif typeid==9 then --object
    javapipe.writeQword(a)
  elseif typeid>10 then --array

    if typeid==13 then
    --check if a is a string
    if type(a)=='string' then
      javapipe.writeDword(#a)
    javapipe.writeString(a)
    return
    end
    --else send it char by char
  end

    javapipe.writeDword(#a) --length of the array

  --send the fields as the given type


  local i
  for i=1, #a do
    java_invokeMethod_sendParameter(typeid-10, a[i], true)
  end

  end

end

function java_invokeMethod(object, methodid, ...)
  local argumentcount=#arg
  local name, sig, gen=java_getMethodName(methodid)

  --parse sig to find out what to give as parameters and what to expect as result (I am assuming the caller KNOWS what he's doing...)

  --format of sig: (ABC)D  () part are the parameters, D is the return type
  local result=nil

  parsedsignature=java_parseSignature(sig)

  --convert returntype to the id used by JAVACMD_INVOKEMETHOD

  local returntype=Java_TypeSigToIDConversion[string.sub(parsedsignature.returntype,1,1)]
  if returntype>=10 then
    error(translate('Array return types are not supported'));
  end

  if argumentcount~=#parsedsignature.parameters then
    error(translate('Parameter count does not match'))
  end



  javapipe.lock()
  javapipe.writeByte(JAVACMD_INVOKEMETHOD)
  javapipe.writeQword(object)
  javapipe.writeQword(methodid)

  javapipe.writeByte(returntype)
  javapipe.writeByte(argumentcount)

  local i
  for i=1, argumentcount do
    local typeid
    typeid=Java_TypeSigToIDConversion[string.sub(parsedsignature.parameters[i],1,1)]
  if typeid==10 then
    typeid=10+Java_TypeSigToIDConversion[string.sub(parsedsignature.parameters[i],2,2)]
  end

    java_invokeMethod_sendParameter(typeid, arg[i])


  end

  result=javapipe.readQword()
  javapipe.unlock()

  if returntype==1 then
    result=result~=0
  elseif returntype==7 then --float
    result=byteTableToFloat(dwordToByteTable(result))
  elseif returntype==8 then --double
    result=byteTableToDouble(qwordToByteTable(result))
  end

  return result
end

function java_findMethod(class, name, sig)
  local cm=java_getClassMethods(class)
  local i
  for i=1,#cm do
    if cm[i].name==name then
    if (sig==nil) or (sig==cm[i].signature) then
      return cm[i].jmethodid
    end

  end
  end

  return nil --still here
end



function java_findAllInstancesFromClass(jClass, lookupmethod)
  local result={}
  local ms=createMemoryStream()  
  
  javapipe.lock()
  javapipe.writeByte(JAVACMD_FINDCLASSINSTANCES)
  javapipe.writeByte(lookupmethod)  
  javapipe.writeQword(jClass)
  
  local streamsize=javapipe.readDword()
  if streamsize and streamsize>0 then
    javapipe.readIntoStream(ms,streamsize);
  end
  javapipe.unlock()
  
  if ms.size>=4 then  
    ms.position=0
    local count=ms.readDword()
    for i=1,count do
      local e={}
      e.jobject=ms.readQword()
      e.address=ms.readQword()
      table.insert(result,e);
    end
  else
    print("JAVACMD_FINDCLASSINSTANCES returned an empty stream")
  end
  
  ms.destroy() 

  return result
end

function java_addToBootstrapClassLoaderPath(segment)
  javapipe.lock()
  javapipe.writeByte(JAVACMD_ADDTOBOOTSTRAPCLASSLOADERPATH)
  javapipe.writeWord(#segment)
  javapipe.writeString(segment)
  javapipe.unlock()
end


function java_addToSystemClassLoaderPath()
  javapipe.lock()
  javapipe.writeByte(JAVACMD_ADDTOSYSTEMCLASSLOADERPATH)
  javapipe.writeWord(#segment)
  javapipe.writeString(segment)
  javapipe.unlock()

end

function java_getFieldDeclaringClass(klass, fieldid)
  local result=nil
  javapipe.lock()
  javapipe.writeByte(JAVACMD_GETFIELDDECLARINGCLASS)
  javapipe.writeQword(klass)
  javapipe.writeQword(fieldid)

  result=javapipe.readQword()

  javapipe.unlock()
  return result
end

function java_getFieldSignature(klass, fieldid)
  local result={}
  javapipe.lock()
  javapipe.writeByte(JAVACMD_GETFIELDSIGNATURE)
  javapipe.writeQword(klass)
  javapipe.writeQword(fieldid)

  local length
  length=javapipe.readWord()
  result.name=javapipe.readString(length)

  length=javapipe.readWord()
  result.signature=javapipe.readString(length)

  length=javapipe.readWord()
  result.generic=javapipe.readString(length)


  javapipe.unlock()
  return result
end

local trueboolstr={}
trueboolstr[tostring(true)]=true
trueboolstr['1']=true

java_writers={} --function(stream,stringvalue) end : returns true if parsed properly
java_writers[0]=function(s) return true end
java_writers[1]=function(s,v) s.writeByte(trueboolstr[v] and 1 or 0) return true end --boolean
java_writers[2]=function(s,v)  --byte
  local vn=tonumber(v) 
  if vn then 
    s.writeByte(vn) 
    return true 
  end 
end --byte
java_writers[3]=function(s,v)  --2 byte (hex formatted)
  local vn
  if v:startsWith('0x') then
    vn=tonumber(v)
  else
    vn=tonumber(v,16)
  end
  if vn then s.writeWord(vn) 
    return true
  end 
end --boolean
java_writers[4]=function(s,v)  --word
  local vn=tonumber(v) 
  if vn then 
    s.writeWord(vn) 
    return true 
  end 
end 
java_writers[5]=function(s,v)  --dword
  local vn=tonumber(v) 
  if vn then 
    s.writeDword(vn) 
    return true 
  end 
end 
java_writers[6]=function(s,v)  --qword
  local vn=tonumber(v) 
  if vn then 
    s.writeQword(vn) 
    return true 
  end 
end 
java_writers[7]=function(s,v)  --float
  local vn=tonumber(v) 
  if vn then 
    local bt=floatToByteTable(v)
    s.write(bt)
    return true 
  end 
end 
java_writers[8]=function(s,v)  --double
  local vn=tonumber(v) 
  if vn then 
    local bt=doubleToByteTable(v)
    s.write(bt)
    return true
  end 
end 
java_writers[9]=java_writers[6] --object (jObject)
java_writers[10]=java_writers[6]  --array (jObject)
java_writers[11]=function(s,v) --string  (utf8 formatted)  
  s.writeWord(#v)
  s.writeString(v)
  return true
end
 

function java_setFieldValues(newValues)   
  --newValues is a table where each entry contains
  --  ObjectOrClass (the object or class to change)
  --  Field
  --  Value (Value is a string)
  
  if #newValues>65535 then
    error('Do not call java_setFieldValues with more than 65535 entries...')
  end
  

  
  
  local ms=createMemoryStream()
  ms.writeByte(JAVACMD_SETFIELDVALUES)
  ms.writeWord(#newValues)
  
  for i=1,#newValues do
    local t
    if newValues[i].Field.InternalType==nil then    
      t=Java_TypeSigToIDConversion[string.sub(newValues[i].Fields.signature,1,1)]
      
      if (t==9) and (Fields[i].signature=='Ljava/lang/String;') then 
        t=11 --handle string special 
      end
      
      newValues[i].Field.InternalType=t
    else
      t=newValues[i].Field.InternalType
    end
    
    ms.writeQword(newValues[i].ObjectOrClass)     
    ms.writeQword(newValues[i].Field.jfieldid)
    ms.writeByte(t)
    ms.writeByte(newValues[i].Field.static and 1 or 0)
    
    local writer=java_writers[t]
    if writer==nil then error('Invalid internal field type at index '..i) end
    
    if writer(ms,newValues[i].Value)~=true then return nil,'Failed interpreting the string :'..newValues[i].Value end
    
    ms.Position=0
    
    javapipe.lock()
    javapipe.writeFromStream(ms, ms.Size)
    javapipe.unlock()
    ms.clear()
  
  end
  
  
end

function java_getFieldValuesFromObject(jobject, Fields)
--gets the value of a group of fields all at once
  
  --print("java_getFieldValuesFromObject for "..jobject)
  local ms=createMemoryStream()
  local results={}  
  
  ms.writeByte(JAVACMD_GETFIELDVALUES)
  ms.writeQword(jobject)
  ms.writeQword(Fields.Class.jclass)
  ms.writeDword(#Fields)
  for i=1,#Fields do   
    local t
    if Fields[i].InternalType==nil then    
      t=Java_TypeSigToIDConversion[string.sub(Fields[i].signature,1,1)]
      
      if (t==9) and (Fields[i].signature=='Ljava/lang/String;') then 
        t=11 --handle string special (not just return <null> or <object>)
      end
      
      Fields[i].InternalType=t
    else
      t=Fields[i].InternalType
    end
    
    ms.writeQword(Fields[i].jfieldid)
   
   
    ms.writeByte(t)
    ms.writeByte(Fields[i].static and 1 or 0)      
  end
  
  ms.position=0
  javapipe.lock()
  javapipe.writeFromStream(ms, ms.Size)  
  ms.clear()    
  local streamsize=javapipe.readDword()
  javapipe.readIntoStream(ms, streamsize)
  javapipe.unlock()
  ms.position=0
  
  local readers={}
  readers[0]=function() return {Value='<void>'} end --void (wtf)
  readers[1]=function() return {Value=tostring(ms.readByte()~=0)} end --boolean
  readers[2]=function() return {Value=string.format("%d",ms.readByte())} end --byte
  readers[3]=function() return {Value=string.format("char: 0x%x",ms.readWord())} end --utf-16 char
  readers[4]=function() return {Value=string.format("%d", ms.readWord())} end --short
  readers[5]=function() return {Value=string.format("%d", ms.readDword())} end --int
  readers[6]=function() return {Value=string.format("%d", ms.readQword())} end --long    
  readers[7]=function() 
    local r=ms.read(4);
    local f=byteTableToFloat(r);
    
    return {Value=string.format("%.2f", f)} 
  end --float    
  readers[8]=function()
    local r=ms.read(8);
    local f=byteTableToDouble(r);
    
    return {Value=string.format("%.2f", f)}
  end --double     
  readers[9]=function()  
    local o=ms.readQword()
    if o==0 then
      return {Value='nil'}
    else
      return {Value='<object>', Object=o}
    end   
  end --object  
  
  readers[10]=function()
    local o=ms.readQword()
    if o==0 then --just returns true if it's not nil
      return {Value='nil'}
    else
      return {Value='<array>', Object=o}
    end   
  end --array
  
  readers[11]=function()
    local isnil=ms.readByte()==0
    
    if isnil then
      return {Value='nil'}
    else
      local sl=ms.readWord()
      return {Value='"'..ms.readString(sl)..'"'}
    end
  end--string

  
  for i=1,#Fields do
    --convert the data to strings
    local t=Fields[i].InternalType
    local r=readers[t]
    if r then
      results[i]=r()
    else
      results[i].Value='<WTF>' --unknown internal type
      results[i].Object=nil
    end
  end
  
  ms.destroy()
  return results
end

function java_getFieldValuesFromAddress(address, Fields)
  --read the memory (get the max offset+bytelength first)
  local mem
  local i
  local maxoffset=0
  for i=1,#Fields do
    if Fields[i].offset>maxoffset then
      maxoffset=Fields[i].offset      
    end
  end
  mem=readBytes(address, maxoffset+8)
  
  --parse the memory (may require a few pointer follow reads)

  
end



function java_getField(jObject, fieldid, signature)

  if signature==nil then
    --I need to figure it out myself I guess...
  local klass=java_getObjectClass(jObject)
  signature=java_getFieldSignature(klass, fieldid).signature

  java_dereferenceLocalObject(klass)
  end

  --parse the signature
  local vartype=Java_TypeSigToIDConversion[string.sub(signature,1,1)]
  if vartype>9 then  --not sure what to do about arrays. For now, force them to 'objects'
    vartype=9
  end

  local result=nil

  javapipe.lock()
  javapipe.writeByte(JAVACMD_GETFIELD)
  javapipe.writeQword(jObject)
  javapipe.writeQword(fieldid)
  javapipe.writeByte(vartype)

  result=javapipe.readQword()

  javapipe.unlock()

  if vartype==1 then
    result=result~=0
  elseif vartype==7 then --float
    result=byteTableToFloat(dwordToByteTable(result))
  elseif vartype==8 then --double
    result=byteTableToDouble(qwordToByteTable(result))
  end

  return result

end

function java_setField(jObject, fieldid, signature, value)
  if signature==nil then
    --I need to figure it out myself I guess...
  local klass=java_getObjectClass(jObject)
  signature=java_getFieldSignature(klass, fieldid).signature

  java_dereferenceLocalObject(klass)
  end

  local vartype=Java_TypeSigToIDConversion[string.sub(signature,1,1)]
  if vartype>9 then  --not sure what to do about arrays. For now, force them to 'objects'
    vartype=9
  end

  if vartype==1 then --boolean
    if value then value=1 else value=0 end
  elseif vartype==7 then
    value=byteTableToDword(floatToByteTable(value))
  elseif vartype==8 then
    value=byteTableToQword(doubleToByteTable(value))
  end

  javapipe.lock()
  javapipe.writeByte(JAVACMD_SETFIELD)
  javapipe.writeQword(jObject)
  javapipe.writeQword(fieldid)
  javapipe.writeByte(vartype)
  javapipe.writeQword(value)
  javapipe.unlock()

end

function java_search_start(value, boolean)
  --tag all known objects and set a variable to let some functions know they can not function until the scan has finished (they can't set tags)
  local result=nil
  javapipe.lock()
  javapipe.writeByte(JAVACMD_STARTSCAN)

  if value==nil then
    javapipe.writeByte(1) --unknown initial value scan
  else
    javapipe.writeByte(0) --value scan
  javapipe.writeDouble(value)
  if (boolean~=nil) and (boolean==true) then
    javapipe.writeByte(1)
  else
    javapipe.writeByte(0)
  end
  end


  result=javapipe.readQword() --Wait till done, get nr of results)

  java_scanning=true


  javapipe.unlock()

  return result
end

function java_search_refine(scantype, scanvalue)
  --refines the result of the current scan
  --scantype:
  --0 = exact value
  --1 = increased value
  --2 = decreased value
  --3 = changed value
  --4 = unchanged value

  local result=nil

  if scantype==nil then
    error(translate("Scantype was not set"))
  end

  javapipe.lock()
  javapipe.writeByte(JAVACMD_REFINESCANRESULTS)
  javapipe.writeByte(scantype)
  if scantype==0 then
    javapipe.writeDouble(scanvalue)
  end


  result=javapipe.readQword()

  javapipe.unlock()

  return result

end

function java_search_getResults(maxresults)
  --get the results
  --note, the results are referencec to the object, so CLEAN UP when done with it (and don't get too many)
  local result={}

  javapipe.lock()
  javapipe.writeByte(JAVACMD_GETSCANRESULTS)
  if maxresults==0 then
    maxresults=10
  end

  javapipe.writeDword(maxresults)


  --local i=1

  while true do
    --print(i)
   -- i=i+1

    local object=javapipe.readQword()
    if (object==0) or (object==nil) then
      --print("End of the list")
      break
    end --end of the list

    local r={}
    r.object=object
    r.fieldid=javapipe.readQword()

    table.insert(result, r)
  end
  javapipe.unlock()

  return result
end


function java_search_finish()
  java_scanning=false
end

function java_foundCodeDialogClose(sender, closeAction)
  --print("closing")
  local id=sender.Tag
  local fcd=java.findwhatwriteslist[id]
  java.findwhatwriteslist[id]=nil


  java_stopFindWhatWrites(id)
  return caFree
end

function java_MoreInfoDblClick(sender)
  --get the class and method and start the editor
  local index=sender.ItemIndex+1
  if index>0 then
    local methodid=getRef(sender.Tag).stack[index].methodid --the listview also has this tag (tag to entry)
    local class=java_getMethodDeclaringClass(methodid)

    --get the class that defines this method

    local classdata=java_getClassData(class)
    local parsedclass=java_parseClass(classdata)

    local mname=java_getMethodName(methodid)
    local parsedmethod=javaclass_findMethod(parsedclass, mname)

    javaclasseditor_editMethod(parsedclass, parsedmethod, editMethod_applyClick, class)

  end
end


function java_foundCodeDialog_MoreInfo_OnDestroy(sender)
  --cleanup the reference to this entry
  local entry=getRef(sender.Tag)
  if entry~=nil then
    entry.form=nil
    destroyRef(sender.Tag)
  end

end


function java_createEntryListView(owner)
  local lv=createListView(owner)
  lv.ViewStyle=vsReport
  lv.ReadOnly=true
  lv.RowSelect=true

  local c=lv.Columns.add()
  c.caption=translate('Class')
  c.width=150

  c=lv.Columns.add()
  c.caption=translate('Method')
  c.width=150

  c=lv.Columns.add()
  c.caption=translate('Position')
  c.autosize=true

  return lv
end

function java_foundCodeDialogLVDblClick(sender)
  local id=sender.tag
  local fcd=java.findwhatwriteslist[id]

  local index=sender.ItemIndex+1
  if index>0 then
    local entry=fcd.entries[index]

    if (entry.stack~=nil) and (entry.form==nil) then
      --show a form with the stack info
      local ref=createRef(entry)
      entry.form=createForm()
      entry.form.Caption=string.format(translate("More info %s.%s(%d)"), entry.classname, entry.methodname, entry.location)
      entry.form.Tag=ref
      entry.form.Width=400
      entry.form.Height=150
      entry.form.Position=poScreenCenter
      entry.form.BorderStyle=bsSizeable


      local lv=java_createEntryListView(entry.form)
      lv.Tag=ref
      lv.Align=alClient
      entry.form.OnDestroy=java_foundCodeDialog_MoreInfo_OnDestroy

      --fill the listview with the data
      local i
      for i=1, #entry.stack do
        local se=entry.stack[i]
        local mname=java_getMethodName(se.methodid)
        local class=java_getMethodDeclaringClass(se.methodid)
        local classname=java_getClassSignature(class)

        java_dereferenceLocalObject(class)
        class=nil

        local tventry=lv.items.add()
        tventry.Caption=classname

        tventry.SubItems.add(string.format('%x: %s', se.methodid, mname))
        tventry.SubItems.add(se.location)
      end

      lv.OnDblClick=java_MoreInfoDblClick

    end

    if (entry.form~=nil) then
      entry.form.show() --bring to front
    end


  end

end

function java_findWhatWrites(object, fieldid)
  local id=nil
  if java.capabilities.can_generate_field_modification_events then
    --spawn a window to receive the data

    javapipe.lock()
    javapipe.writeByte(JAVACMD_FINDWHATWRITES)
    javapipe.writeQword(object)
    javapipe.writeQword(fieldid)

    id=javapipe.readDword()

    --print("id="..id)

    javapipe.unlock()


    local fcd={} --found code dialog
    fcd.form=createForm()
    fcd.form.width=400
    fcd.form.height=300
    fcd.form.Position=poScreenCenter
    fcd.form.BorderStyle=bsSizeable
    fcd.form.caption=translate('The following methods accessed the given variable')
    fcd.form.OnClose=java_foundCodeDialogClose
    fcd.form.Tag=id

    fcd.lv=java_createEntryListView(fcd.form)
    fcd.lv.Align=alClient
    fcd.lv.OnDblClick=java_foundCodeDialogLVDblClick
    fcd.lv.Tag=id
    fcd.lv.Name=translate('results');


    fcd.entries={}


    if java.findwhatwriteslist==nil then
      java.findwhatwriteslist={}
    end

    java.findwhatwriteslist[id]=fcd
  else
    error(translate('java_find_what_writes only works when the jvmti agent is launched at start'))
  end

  return id
end

function java_stopFindWhatWrites(id)
  javapipe.lock()
  javapipe.writeByte(JAVACMD_STOPFINDWHATWRITES)
  javapipe.writeDword(id)
  javapipe.unlock()
end

function java_getMethodDeclaringClass(methodid)
  javapipe.lock()
  javapipe.writeByte(JAVACMD_GETMETHODDECLARINGCLASS)
  javapipe.writeQword(methodid)
  local result=javapipe.readQword()
  javapipe.unlock()

  return result
end


function java_android_decodeObject(jobject)
  local result=0
  javapipe.lock()
  javapipe.writeByte(JAVACMD_ANDROID_DECODEOBJECT)
  javapipe.writeQword(jobject)
  result=javapipe.readQword()
  javapipe.unlock()
  return result 
end



function java_getObjectHandleToAddress(address)
  local result=0
  javapipe.lock()
  javapipe.writeByte(JAVACMD_FINDJOBJECT)
  javapipe.writeQword(address)

  result=javapipe.readQword()
  javapipe.unlock()


  return result
end


function java_getObjectClass(jObject)
  local result
  javapipe.lock()

  javapipe.writeByte(JAVACMD_GETOBJECTCLASS);
  javapipe.writeQword(jObject)
  result=javapipe.readQword()


  javapipe.unlock()
  return result
end

function java_getObjectClassName(jObject)
  local result
  javapipe.lock()

 -- printf("java_getObjectClassName. JAVAVMD_GETOBJECTCLASSNAME=%d",JAVAVMD_GETOBJECTCLASSNAME) 
  javapipe.writeByte(JAVAVMD_GETOBJECTCLASSNAME);
  javapipe.writeQword(jObject)
  local length=javapipe.readWord()
  result=javapipe.readString(length)

  javapipe.unlock()
  return result
end

function java_getClassSignature(jClass)
  local length
  local result=''
  javapipe.lock()
  javapipe.writeByte(JAVACMD_GETCLASSSIGNATURE)
  javapipe.writeQword(jClass)

  length=javapipe.readWord()
  result=javapipe.readString(length)

  length=javapipe.readWord()
  if (length>0) then
    result=result..translate('  Generic=')..javapipe.readString(length);
  end

  javapipe.unlock()

  return result
end

function java_getSuperClass(jClass)
  local result=nil
  javapipe.lock()
  javapipe.writeByte(JAVACMD_GETSUPERCLASS)
  javapipe.writeQword(jClass)

  result=javapipe.readQword()
  javapipe.unlock()

  return result
end


function java_findFields(name, signature, caseSensitive)
  if (name==nil or name=='') and (signature==nil or signature=='') then return {} end
 
  javapipe.lock()
  javapipe.writeByte(JAVACMD_FINDFIELDS)
  javapipe.writeByte((caseSensitive and 1) or 0)
  
  if name then
    javapipe.writeWord(#name)  
    javapipe.writeString(name)  
  else 
    javapipe.writeWord(0)
  end
  
  
  if signature then  
    javapipe.writeWord(#signature)  
    javapipe.writeString(signature)
  else
   javapipe.writeWord(0)
  end
  
  local streamsize=javapipe.readDword()
  local ms=createMemoryStream()
  javapipe.readIntoStream(ms,streamsize)
  javapipe.unlock()    
  
  ms.Position=0
  
  local result={}
  
  while ms.Position<ms.Size do
    local e={}
    e.jclass=ms.readQword()
    e.fieldid=ms.readQword()
    table.insert(result,e)
  end
  
  ms.destroy()
  
  return result
end

function java_findMethods(name, signature, caseSensitive)
  if (name==nil or name=='') and (signature==nil or signature=='') then return {} end
 
  javapipe.lock()
  javapipe.writeByte(JAVACMD_FINDMETHODS)
  javapipe.writeByte((caseSensitive and 1) or 0)
  
  if name then
    javapipe.writeWord(#name)  
    javapipe.writeString(name)  
  else 
    javapipe.writeWord(0)
  end
  
  
  if signature then  
    javapipe.writeWord(#signature)  
    javapipe.writeString(signature)
  else
   javapipe.writeWord(0)
  end
  
  local streamsize=javapipe.readDword()
  local ms=createMemoryStream()
  javapipe.readIntoStream(ms,streamsize)
  javapipe.unlock()    
  
  ms.Position=0
  
  local result={}
  
  while ms.Position<ms.Size do
    local e={}
    e.jclass=ms.readQword()
    e.methodid=ms.readQword()
    table.insert(result,e)
  end
  
  ms.destroy()
  
  return result
end




function miJavaActivateClick(sender)
  javaInjectAgent()
end


--[[
function javaForm_treeviewExpanding(sender, node)
  local allow=true

  --outputDebugString("Expanding "..node.Text)

  --print("javaForm_treeviewExpanding "..node.level)
  if node.Level==0 then --root level (class expasion)
    if node.Count==0 then  --not yet filled in
      --expand the class this node describes
      local jklass=node.Data
      local methods=java_getClassMethods(jklass)
      local fields=java_getClassFields(jklass)
      local interfaces=java_getImplementedInterfaces(jklass)
      local superclass=java_getSuperClass(jklass)

      local i

      if superclass~=0 then
        node.add(translate('superclass=')..java_getClassSignature(superclass))
        java_dereferenceLocalObject(superclass)
      end



      node.add(translate('---Implemented interfaces---'));
      for i=1, #interfaces do
        local name
        if interfaces[i]>0 then
          name=java_getClassSignature(interfaces[i])
        else
          name='???'
        end

        node.add(string.format("%x : %s", interfaces[i], name))
      end

      node.add(translate('---Fields---'));
      for i=1, #fields do
        node.add(string.format("%x: %s: %s (%s)", fields[i].jfieldid, fields[i].name, fields[i].signature,fields[i].generic))
      end

      node.add(translate('---Methods---'));

      for i=1, #methods do
        local n=node.add(string.format("%x: %s%s           %s", methods[i].jmethodid, methods[i].name, methods[i].signature, methods[i].generic))
        n.data=methods[i].jmethodid  --ONLY methods have this field set at level 1. (!ONLY METHODS!)
      end


    --java_getClassFields(jklass);
    end
  end

  return allow
end

function javaForm_searchClass(sender)
  javaForm.findAll=false --classes only
  javaForm.findDialog.Title=translate("Search for class...")
  javaForm.findDialog.execute()
end

function javaForm_searchAll(sender)
  javaForm.findAll=true --everything
  javaForm.findDialog.Title=translate("Search for...")
  javaForm.findDialog.execute()
end

function javaForm_doSearch(sender)
  --search for javaForm.findDialog.FindText
  local currentindex=1
  local findall=javaForm.findAll
  local searchstring=javaForm.findDialog.FindText

  if javaForm.treeview.Selected ~= nil then
    currentindex=javaForm.treeview.Selected.AbsoluteIndex+1 --start at the next one
  end

  while currentindex<javaForm.treeview.Items.Count do
    local node=javaForm.treeview.Items[currentindex]

    if (node.level==0) or findall then
      --check if node.Text contains the searchstring
     if string.find(node.Text,searchstring) ~= nil then
        --found one
        node.Selected=true
        node.makeVisible()
        return
      end
    end

    if findall and node.HasChildren then
      node.expand()
    end
    currentindex=currentindex+1
  end
end--]]

function varscan_showResults(count)
  --print("showing results for "..count.." results");
  java.varscan.currentresults=java_search_getResults(math.min(count, 100))



  if count>100 then
    java.varscan.Count.Caption=string.format('%d of %d', #java.varscan.currentresults, count)
  else
    java.varscan.Count.Caption=count
  end

  count=#java.varscan.currentresults


  local i
  for i=1,count do
    local object=java.varscan.currentresults[i].object
    local fieldid=java.varscan.currentresults[i].fieldid



    local class=java_getObjectClass(object)
    local classname=java_getClassSignature(class)

    --local class2=java_getFieldDeclaringClass(class, fieldid)
    local fieldname=java_getFieldSignature(class, fieldid)
    java_dereferenceLocalObject(class)
    --java_dereferenceLocalObject(class2)

    java.varscan.Results.Items.Add('Obj('..classname..'.'..fieldname.name..')')
  end
end

function varscan_cleanupResults()
  local i

  java.varscan.Results.clear()

  for i=1,#java.varscan.currentresults do
    java_dereferenceLocalObject(java.varscan.currentresults[i].object)
  end

  java.varscan.currentresults=nil
end

function varscan_firstScan(sender)
  --print("first scan")
  if (sender.Tag==0) then
    --first scan

    local count=java_search_start(java.varscan.ValueBox.Text)
    varscan_showResults(count)


    sender.Caption=translate("New Scan")
    sender.Tag=1

    java.varscan.NextScan.Enabled=#java.varscan.currentresults>0
  else
    --new scan
    varscan_cleanupResults()
    java_search_finish()
    java.varscan.NextScan.Enabled=false

    sender.Caption=translate("First Scan")
    sender.Tag=0
  end
end

function varscan_nextScan(sender)
  --print("next scan")
  varscan_cleanupResults()

  local count=java_search_refine(0, java.varscan.ValueBox.Text)
  varscan_showResults(count)

  java.varscan.NextScan.Enabled=#java.varscan.currentresults>0

end

function miFindWhatAccessClick(sender)
  local i=java.varscan.Results.ItemIndex
  if i~=-1 then
    i=i+1
    local object=java.varscan.currentresults[i].object
    local fieldid=java.varscan.currentresults[i].fieldid

    java_findWhatWrites(object, fieldid)
  end
end

function miJavaVariableScanClick(sender)
  javaInjectAgent()

  local varscan=java.varscan

  if varscan==nil then
    --build a gui
    varscan={}
    varscan.form=createForm()
    varscan.form.Width=400
    varscan.form.Height=400
    varscan.form.Position=poScreenCenter
    varscan.form.Caption=translate("Java Variable Scanner")
    varscan.form.BorderStyle=bsSizeable


    varscan.controls=createPanel(varscan.form)
    varscan.controls.Align=alRight
    varscan.controls.Caption=''
    varscan.controls.BevelOuter="bvNone"


    varscan.ValueText=createLabel(varscan.controls)
    varscan.ValueText.Caption=translate("Value")

    varscan.FirstScan=createButton(varscan.controls)
    varscan.FirstScan.Caption=translate("First Scan")

    varscan.NextScan=createButton(varscan.controls)
    varscan.NextScan.Caption=translate("Next Scan")

    local width=6+math.max(varscan.form.Canvas.getTextWidth(varscan.FirstScan.Caption), varscan.form.Canvas.getTextWidth(varscan.NextScan.Caption)) --guess which one will be bigger... (just in case someone translates this)

    varscan.FirstScan.ClientWidth=width
    varscan.NextScan.ClientWidth=width

    varscan.ValueBox=createEdit(varscan.controls)

    varscan.ValueBox.Top=20
    varscan.ValueBox.Left=20;

    varscan.ValueText.AnchorSideLeft.Control=varscan.ValueBox
    varscan.ValueText.AnchorSideLeft.Side=asrLeft
    varscan.ValueText.AnchorSideBottom.Control=varscan.ValueBox
    varscan.ValueText.AnchorSideBottom.Side=asrTop
    varscan.ValueText.Anchors="[akLeft, akBottom]"


    varscan.FirstScan.AnchorSideLeft.Control=varscan.ValueBox
    varscan.FirstScan.AnchorSideLeft.Side=asrLeft

    varscan.FirstScan.AnchorSideTop.Control=varscan.ValueBox
    varscan.FirstScan.AnchorSideTop.Side=asrBottom
    varscan.FirstScan.BorderSpacing.Top=5
    varscan.FirstScan.Anchors="[akTop, akLeft]"
    varscan.FirstScan.OnClick=varscan_firstScan

    varscan.NextScan.AnchorSideLeft.Control=varscan.FirstScan
    varscan.NextScan.AnchorSideLeft.Side=asrRight
    varscan.NextScan.BorderSpacing.Left=5
    varscan.NextScan.OnClick=varscan_nextScan

    varscan.NextScan.AnchorSideTop.Control=varscan.ValueBox
    varscan.NextScan.AnchorSideTop.Side=asrBottom
    varscan.NextScan.BorderSpacing.Top=5
    varscan.NextScan.Anchors="[akTop, akLeft]"
    varscan.NextScan.Enabled=false

    varscan.ValueBox.Width=varscan.NextScan.Left+varscan.NextScan.Width-varscan.ValueBox.Left
    varscan.controls.Width=varscan.ValueBox.Width+40

    varscan.ResultPanel=createPanel(varscan.form)
    varscan.ResultPanel.Align=alClient
    varscan.ResultPanel.Caption=""
    varscan.ResultPanel.BevelOuter="bvNone"


    varscan.Count=createLabel(varscan.ResultPanel)
    varscan.Count.Caption=translate("Found:")
    varscan.Count.Align=alTop

    varscan.Results=createListBox(varscan.ResultPanel)
    varscan.Results.Align=alClient
    varscan.Results.Width=200

    varscan.Results.PopupMenu=createPopupMenu(varscan.form)

    local mi
    mi=createMenuItem(varscan.Results.PopupMenu)
    mi.Caption=translate("Find what accesses this value")
    mi.OnClick=miFindWhatAccessClick;
    varscan.Results.PopupMenu.Items.add(mi)

  end

  varscan.form.show()

  java.varscan=varscan
end

function editMethod_applyClick(parsedclass, class)
  local newdata=java_writeClass(parsedclass)
  java_redefineClassWithCustomData(class, newdata)


end

function miEditMethodClick(sender)
  --javaclasseditor_editMethod(class, methodid)
  local sel=javaForm.treeview.Selected
  if (sel~=nil) and (sel.Level==1) and (sel.Data~=0) then
    --find the class and the methodid
    --class can be found in the parent
    --methodid is in the data

    local class=sel.Parent.Data
    local methodid=sel.data

    --javaclasseditor_editMethod(class, methodid)

    local classdata=java_getClassData(class)
    local parsedclass=java_parseClass(classdata)

    local mname=java_getMethodName(methodid)
    local parsedmethod=javaclass_findMethod(parsedclass, mname)

    javaclasseditor_editMethod(parsedclass, parsedmethod, editMethod_applyClick, class)
  end
end


function javaDissectPopupOnPopup(sender)
  --check if the current line contains a method, and if so, show miEditMethod else hide it

  local sel=javaForm.treeview.Selected
  javaForm.miEditMethod.Visible=(sel~=nil) and (sel.Level==1) and (sel.Data~=0)
end









function miJavaSetEnvironmentClick(sender)
  if targetIs64Bit() then
  autoAssemble([[
alloc(newenv, 32768)

alloc(sev, 2048)
alloc(path, 512)

alloc(pathstr,5)
alloc(JTOstr, 18)
alloc(JTO, 19)
label(end)
label(hasnosemicolon)
label(copyoption)


path:
{$lua}
return "db ';"..getCheatEngineDir().."autorun\\dlls\\32;"..getCheatEngineDir().."autorun\\dlls\\64',0"
{$asm}

pathstr:
db 'PATH',0

JTOstr:
db 'JAVA_TOOL_OPTIONS',0

JTO:
db ' -agentlib:cejvmti',0

sev:

//sub rsp,8 //align the stack
//sub rsp,20 //allocate scratchspace for function calls
sub rsp,28 //using magic to compine those two

//set the path
mov rcx,pathstr
mov rdx,newenv
mov r8,8000

call GetEnvironmentVariableA


mov rdx,path

cmp byte [newenv+rax],';'
jne hasnosemicolon

add rdx,1 //it already has a semicolon so skip it

hasnosemicolon:

mov rcx,newenv
//rdx=path(+1)
call ntdll.strcat

mov rcx,pathstr
mov rdx,newenv
call SetEnvironmentVariableA


//set the java tool options
mov byte [newenv],0


mov rcx,JTOstr
mov rdx,newenv
mov r8,8000
call GetEnvironmentVariableA

mov rdx, JTO

cmp rax,0 //not yet defined
jne copyoption

//it hasn't been defined yet
add rdx,1 //no space

copyoption:

mov rcx,newenv
//rdx=rdx
call ntdll.strcat

mov rcx,JTOstr
mov rdx,newenv
call SetEnvironmentVariableA


end:

add rsp,28
ret

createthread(sev)
]])

  else
  autoAssemble([[
alloc(newenv, 32768)

alloc(sev, 2048)
alloc(path, 512)

alloc(pathstr,5)
alloc(JTOstr, 18)
alloc(JTO, 19)
label(end)
label(hasnosemicolon)
label(copyoption)


path:
{$lua}
return "db ';"..getCheatEngineDir().."autorun\\dlls\\32;"..getCheatEngineDir().."autorun\\dlls\\64',0"
{$asm}

pathstr:
db 'PATH',0

JTOstr:
db 'JAVA_TOOL_OPTIONS',0

JTO:
db ' -agentlib:cejvmti',0

sev:

//set the path
push 8000
push newenv
push pathstr
call GetEnvironmentVariableA


mov esi,path


cmp byte [newenv+eax],';'
jne hasnosemicolon

add esi,1 //it already has a semicolon so skip it

hasnosemicolon:

push esi
push newenv
call ntdll.strcat
add esp,8


push newenv
push pathstr
call SetEnvironmentVariableA


//set the java tool options
mov byte [newenv],0

push 8000
push newenv
push JTOstr
call GetEnvironmentVariableA

mov esi, JTO

cmp eax,0 //not yet defined
jne copyoption

//it hasn't been defined yet
add esi,1 //no space

copyoption:

push esi
push newenv
call ntdll.strcat
add esp,8

push newenv
push JTOstr
call SetEnvironmentVariableA


end:
ret

createthread(sev)

  ]]
  )
  end
end

function java_OpenProcessAfterwards()
  local usesjava=false
  local m=enumModules()
  local i

  java_classlist=nil

  for i=1, #m do
    if m[i].Name=='jvm.dll' then
      java.android=false
      usesjava=true
      break
    end
    
    if m[i].Name=='libart.so' then
      java.android=true
      usesjava=true
      break    
    end
  end
  
  synchronize(function()
    if usesjava or java.settings.cbAlwaysShowMenu.Checked then
      if (miJavaTopMenuItem==nil) then
        local mfm=getMainForm().Menu
        local mi

        miJavaTopMenuItem=createMenuItem(mfm)
        local s="Java"
        
        if java.android then
          s=s.." (Android)"
        end
        miJavaTopMenuItem.Caption=s
        mfm.Items.insert(mfm.Items.Count-1, miJavaTopMenuItem) --add it before help


        mi=createMenuItem(miJavaTopMenuItem)
        mi.Caption=translate("Activate java features")
        mi.OnClick=miJavaActivateClick
        mi.Enabled=usesjava
        mi.Name="miActivate"
        mi.Visible=false
        miJavaTopMenuItem.Add(mi)

        mi=createMenuItem(miJavaTopMenuItem)
        mi.Caption=translate("Java Info")
        mi.Shortcut="Ctrl+Alt+J"
        mi.OnClick=miJavaInfoClick
        mi.Enabled=usesjava
        mi.Name="miDissectJavaClasses"
        miJavaTopMenuItem.Add(mi)

        mi=createMenuItem(miJavaTopMenuItem)
        mi.Caption=translate("Java variable scan")
        mi.Shortcut="Ctrl+Alt+S"
        mi.OnClick=miJavaVariableScanClick
        mi.Enabled=usesjava
        mi.Name="miJavaVariableScan"
        miJavaTopMenuItem.Add(mi)

        if (not java.android) then
          --debug child processes sets the environment option so a spawned child will instantly load the jvmti
          mi=createMenuItem(miJavaTopMenuItem)
          mi.Caption="-"
          miJavaTopMenuItem.Add(mi)

          mi=createMenuItem(miJavaTopMenuItem)
          mi.Caption=translate("Debug child processes")
          mi.OnClick=miJavaSetEnvironmentClick
          mi.Enabled=getOpenedProcessID()~=0
          mi.Name="miDebugChildren"
          miJavaTopMenuItem.Add(mi)
        end
      else
        miJavaTopMenuItem.miActivate.enabled=usesjava
        miJavaTopMenuItem.miDissectJavaClasses.enabled=usesjava
        miJavaTopMenuItem.miJavaVariableScan.enabled=usesjava
        miJavaTopMenuItem.miDebugChildren=getOpenedProcessID()~=0
      end
    end
  end)
end

function java_OpenProcess(processid)
  if java.oldOnOpenProcess~=nil then
    java.oldOnOpenProcess(processid)
  end

  if java_OpenProcessAfterwards_Thread==nil then
    java_OpenProcessAfterwards_Thread=createThread(function(t)
      t.Name='java_OpenProcessAfterwards'
      --print("java_OpenProcessAfterwards")
      java_OpenProcessAfterwards()
      java_OpenProcessAfterwards_Thread=nil    
      --print("java_OpenProcessAfterwards done")
    end )
  end
    --call this function when the whole OpenProcess routine is done (next sync check)
end

function javaAA_USEJAVA(parameters, syntaxcheckonly)
  --called whenever an auto assembler script encounters the USEJAVA() line
  --the value you return will be placed instead of the given line
  --In this case, returning a empty string is fine
  --Special behaviour: Returning nil, with a secondary parameter being a string, will raise an exception on the auto assembler with that string


  if (syntaxcheckonly==false) and (not javaInjectAgent()) then
    return nil,translate("The java handler failed to initialize")
  end

  return "" --return an empty string (removes it from the internal aa assemble list)
end


function java_settingsClose(sender, closeAction)
  local result=closeAction
  if java.settingsOnClose~=nil then
    result=java.settingsOnClose(sender, closeAction)
  end

  if (result==caHide) and (sender.ModalResult==mrOK) then
    --Apply changes

    --if there is an error return caNone (and show a message preferably)
    if java.settings.cbAlwaysShowMenu.Checked then
      java.settings.registry.Value["Always Show Menu"]=1
    else
      java.settings.registry.Value["Always Show Menu"]=0
    end

    --[[
    if java.settings.cbGlobalHook.Checked then
      if (java.settings.registry.Value["Global Hook"]=='') or (java.settings.registry.Value["Global Hook"]==0) then
        --it got selected
      end

      java.settings.registry.Value["Global Hook"]=1
    else
      if java.settings.registry.Value["Global Hook"]==1 then
        --it got deselected
      end
        java.settings.registry.Value["Global Hook"]=0
    end
    --]]

  end
  return result
end

function java_settingsShow(sender)
  if java.settingsOnShow~=nil then
    result=java.settingsOnShow(sender)
  end

  --update the controls based on the registry
  java.settings.cbAlwaysShowMenu.Checked=java.settings.registry.Value["Always Show Menu"]=='1'
  --java.settings.cbGlobalHook.Checked=java.settings.registry.Value["Global Hook"]=='1'

end

function java_initialize()
  --register a function to be called when a process is opened
  if (java==nil) then
    addCIncludePath(getAutorunPath()..'java')
  
    java={}
    java.oldOnOpenProcess=onOpenProcess
    onOpenProcess=java_OpenProcess

    registerAutoAssemblerCommand("USEJAVA", javaAA_USEJAVA)


    local sf=getSettingsForm()
    java.settingsTab=sf.SettingsPageControl.addTab()


    local insertNode=sf.SettingsTreeView.Items[3]  --insert it near the unrandomizer since it'd be used as often as that setting
    local node=sf.SettingsTreeView.Items.insert(insertNode, "Java")
    node.data=userDataToInteger(java.settingsTab)

    java.settingsOnClose=sf.onClose
    sf.onClose=java_settingsClose

    java.settingsOnShow=sf.onShow
    sf.onShow=java_settingsShow


    java.settings={}

    local cbAlwaysShowMenu=createCheckBox(java.settingsTab)
    cbAlwaysShowMenu.Caption=translate("Show java menu item even if the target process hasn't loaded jvm.dll (Used for the local setEnvironment option)")
    cbAlwaysShowMenu.AnchorSideLeft.Control=java.settingsTab
    cbAlwaysShowMenu.AnchorSideLeft.Side=asrLeft

    cbAlwaysShowMenu.AnchorSideTop.Control=java.settingsTab
    cbAlwaysShowMenu.AnchorSideTop.Side=asrTop

    cbAlwaysShowMenu.Anchors="[akTop, akLeft]"

    java.settings.cbAlwaysShowMenu=cbAlwaysShowMenu

  --[[
  --warning: If you uninstall CE while this is checked you won't be able to load any java programs

  local cbGlobalHook=createCheckBox(java.settingsTab)
  cbGlobalHook.Caption="Systemwide java agent injection. (Loads the java agent even when CE isn't running. Reboot recommended)"
  cbGlobalHook.AnchorSideLeft.Control=java.settingsTab
  cbGlobalHook.AnchorSideLeft.Side=asrLeft

  cbGlobalHook.AnchorSideTop.Control=cbAlwaysShowMenu
  cbGlobalHook.AnchorSideTop.Side="asrBottom"
  cbGlobalHook.Anchors="[akTop, akLeft]"

  java.settings.cbGlobalHook=cbGlobalHook
  --]]

    java.settings.registry=getSettings("Java")


    --initialize the settings based on the registry
    java.settings.cbAlwaysShowMenu.Checked=java.settings.registry.Value["Always Show Menu"]=='1'
    --java.settings.cbGlobalHook.Checked=java.settings.registry.Value["Global Hook"]=='1'



  end
end


java_initialize()
