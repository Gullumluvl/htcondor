# Microsoft Developer Studio Project File - Name="condor_gridmanager" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Console Application" 0x0103

CFG=condor_gridmanager - Win32 Release
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "condor_gridmanager.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "condor_gridmanager.mak" CFG="condor_gridmanager - Win32 Release"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "condor_gridmanager - Win32 Debug" (based on "Win32 (x86) Console Application")
!MESSAGE "condor_gridmanager - Win32 Release" (based on "Win32 (x86) Console Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "condor_gridmanager - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "..\Debug"
# PROP Intermediate_Dir "..\Debug"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /c
# ADD CPP /nologo /MTd /W3 /Gm /Gi /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /Fp"..\Debug\condor_common.pch" /Yu"condor_common.h" /FD /TP $(CONDOR_INCLUDE) $(CONDOR_DEFINES) $(CONDOR_CPPARGS) $(CONDOR_GSOAP_INCLUDE) $(CONDOR_GLOBUS_INCLUDE) $(CONDOR_KERB_INCLUDE) $(CONDOR_PCRE_INCLUDE) $(CONDOR_OPENSSL_INCLUDE) $(CONDOR_POSTGRESQL_INCLUDE) /c
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 /nologo /subsystem:console /debug /machine:I386 /pdbtype:sept
# ADD LINK32 ../Debug/condor_common.obj ..\Debug\condor_common_c.obj $(CONDOR_LIB) $(CONDOR_LIBPATH) $(CONDOR_GSOAP_LIB) $(CONDOR_GSOAP_LIBPATH) $(CONDOR_KERB_LIB) $(CONDOR_KERB_LIBPATH) $(CONDOR_PCRE_LIB) $(CONDOR_PCRE_LIBPATH) $(CONDOR_GLOBUS_LIB) $(CONDOR_GLOBUS_LIBPATH) $(CONDOR_OPENSSL_LIB) $(CONDOR_POSTGRESQL_LIB) $(CONDOR_OPENSSL_LIBPATH) $(CONDOR_POSTGRESQL_LIBPATH) /nologo /subsystem:console /debug /machine:I386 /pdbtype:sept
# SUBTRACT LINK32 /map

!ELSEIF  "$(CFG)" == "condor_gridmanager - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "condor_gridmanager___Win32_Release"
# PROP BASE Intermediate_Dir "condor_gridmanager___Win32_Release"
# PROP BASE Ignore_Export_Lib 0
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "../Release"
# PROP Intermediate_Dir "../Release"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MDd /W3 /GX /Z7 /Od /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /Fp"..\src\condor_c++_util/condor_common.pch" /Yu"condor_common.h" /FD /TP /c
# SUBTRACT BASE CPP /Fr
# ADD CPP /nologo /MT /W3 /GX /Z7 /O1 /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /Fp"..\Release\condor_common.pch" /Yu"condor_common.h" /FD /TP $(CONDOR_INCLUDE) $(CONDOR_DEFINES) $(CONDOR_CPPARGS) $(CONDOR_GSOAP_INCLUDE) $(CONDOR_GLOBUS_INCLUDE) $(CONDOR_KERB_INCLUDE) $(CONDOR_PCRE_INCLUDE) $(CONDOR_OPENSSL_INCLUDE) $(CONDOR_POSTGRESQL_INCLUDE) /c
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 /nologo /subsystem:console /debug /machine:I386 /pdbtype:sept
# SUBTRACT BASE LINK32 /map
# ADD LINK32 ../Release/condor_common.obj ..\Release\condor_common_c.obj $(CONDOR_LIB) $(CONDOR_LIBPATH) $(CONDOR_GSOAP_LIB) $(CONDOR_GSOAP_LIBPATH) $(CONDOR_KERB_LIB) $(CONDOR_KERB_LIBPATH) $(CONDOR_PCRE_LIB) $(CONDOR_PCRE_LIBPATH) $(CONDOR_GLOBUS_LIB) $(CONDOR_GLOBUS_LIBPATH) $(CONDOR_OPENSSL_LIB) $(CONDOR_POSTGRESQL_LIB) $(CONDOR_OPENSSL_LIBPATH) $(CONDOR_POSTGRESQL_LIBPATH) /nologo /subsystem:console /pdb:none /map /debug /machine:I386

!ENDIF 

# Begin Target

# Name "condor_gridmanager - Win32 Debug"
# Name "condor_gridmanager - Win32 Release"
# Begin Source File

SOURCE=..\src\condor_gridmanager\amazonjob.cpp
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\amazonjob.h
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\amazonresource.cpp
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\amazonresource.h
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\basejob.cpp
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\basejob.h
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\baseresource.cpp
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\baseresource.h
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\condorjob.cpp
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\condorjob.h
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\condorresource.cpp
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\condorresource.h
# End Source File
# Begin Source File

SOURCE="..\src\condor_gridmanager\gahp-client.cpp"
# End Source File
# Begin Source File

SOURCE="..\src\condor_gridmanager\gahp-client.h"
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\globusjob.cpp
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\globusjob.h
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\globusresource.cpp
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\globusresource.h
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\gridftpmanager.cpp
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\gridftpmanager.h
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\gridmanager.cpp
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\gridmanager.h
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\gridmanager_main.cpp
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\gt4job.cpp
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\gt4job.h
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\gt4resource.cpp
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\gt4resource.h
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\infnbatchjob.cpp
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\infnbatchjob.h
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\mirrorjob.cpp
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\mirrorjob.h
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\mirrorresource.cpp
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\mirrorresource.h
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\nordugridjob.cpp
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\nordugridjob.h
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\nordugridresource.cpp
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\nordugridresource.h
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\proxymanager.cpp
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\proxymanager.h
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\soap_gridmanagerC.cpp
# SUBTRACT CPP /YX /Yc /Yu
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\soap_gridmanagerH.h
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\soap_gridmanagerServer.cpp
# SUBTRACT CPP /YX /Yc /Yu
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\soap_gridmanagerStub.cpp
# SUBTRACT CPP /YX /Yc /Yu
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\soap_gridmanagerStub.h
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\unicorejob.cpp
# End Source File
# Begin Source File

SOURCE=..\src\condor_gridmanager\unicorejob.h
# End Source File
# End Target
# End Project
