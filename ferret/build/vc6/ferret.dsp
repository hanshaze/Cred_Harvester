# Microsoft Developer Studio Project File - Name="ferret" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Console Application" 0x0103

CFG=ferret - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "ferret.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "ferret.mak" CFG="ferret - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "ferret - Win32 Release" (based on "Win32 (x86) Console Application")
!MESSAGE "ferret - Win32 Debug" (based on "Win32 (x86) Console Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""$/Ferret/build/win32-x86-vc6", YDAAAAAA"
# PROP Scc_LocalPath "."
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "ferret - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "../../bin/Release"
# PROP Intermediate_Dir "../../bin/Release"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /c
# ADD CPP /nologo /W4 /GX /Zi /O1 /I "../../src/include" /I "../../src/target/win32-x86-vc6" /I "../../src" /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /FR /FD /c
# SUBTRACT CPP /YX
# ADD BASE RSC /l 0x1009 /d "NDEBUG"
# ADD RSC /l 0x1009 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /machine:I386
# ADD LINK32 setargv.obj /nologo /subsystem:console /profile /map /debug /machine:I386

!ELSEIF  "$(CFG)" == "ferret - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 2
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "../../bin/Debug"
# PROP Intermediate_Dir "../../tmp/Debug"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /GZ /c
# ADD CPP /nologo /MDd /W4 /Gm /GX /ZI /Od /I "../../src/include" /I "../../src/target/win32-x86-vc6" /I "../../src" /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /D "_AFXDLL" /D malloc=t_malloc /D free=t_free /FR /FD /GZ /c
# SUBTRACT CPP /YX
# ADD BASE RSC /l 0x1009 /d "_DEBUG"
# ADD RSC /l 0x1009 /d "_DEBUG" /d "_AFXDLL"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /debug /machine:I386 /pdbtype:sept
# ADD LINK32 setargv.obj /nologo /subsystem:console /debug /machine:I386 /pdbtype:sept

!ENDIF 

# Begin Target

# Name "ferret - Win32 Release"
# Name "ferret - Win32 Debug"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Group "parser"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\..\src\parser\atalknbp.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\bittorrentdht.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\callwaveiam.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\cisco.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\cups.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\dhcp.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\dns.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\dnsmulticast.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\dnsnetbios.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\dnssrv.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\isakkmp.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\jpeg.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\ldap.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\netbios_dgm.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\ppp.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\sip.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\smb_dgm.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\snmp.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\srvloc.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\ssdp.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\tivo.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\upnp.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\ymsg.c
# End Source File
# End Group
# Begin Group "module"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\..\src\module\ahocorasick.c
# End Source File
# Begin Source File

SOURCE=..\..\src\module\base64.c
# End Source File
# Begin Source File

SOURCE=..\..\src\module\base64.h
# End Source File
# Begin Source File

SOURCE=..\..\src\module\hamster.c
# End Source File
# Begin Source File

SOURCE=..\..\src\module\hexval.c
# End Source File
# Begin Source File

SOURCE=..\..\src\module\housekeeping.c
# End Source File
# Begin Source File

SOURCE=..\..\src\module\housekeeping.h
# End Source File
# Begin Source File

SOURCE=..\..\src\module\malloctrac.c
# End Source File
# Begin Source File

SOURCE=..\..\src\module\md5rfc1321.c
# End Source File
# Begin Source File

SOURCE=..\..\src\module\mystring.c
# End Source File
# Begin Source File

SOURCE=..\..\src\module\mystring.h
# End Source File
# Begin Source File

SOURCE=..\..\src\module\pcapfile.c
# End Source File
# Begin Source File

SOURCE=..\..\src\module\pcapfile.h
# End Source File
# Begin Source File

SOURCE=..\..\src\module\pcaplive.c
# End Source File
# Begin Source File

SOURCE=..\..\src\module\pcaplive.h
# End Source File
# Begin Source File

SOURCE=..\..\src\module\stringtab.c
# End Source File
# Begin Source File

SOURCE=..\..\src\module\stringtab.h
# End Source File
# Begin Source File

SOURCE=..\..\src\module\tcpfrag.c
# End Source File
# Begin Source File

SOURCE=..\..\src\module\tcpfrag.h
# End Source File
# Begin Source File

SOURCE=..\..\src\module\val2string.c
# End Source File
# Begin Source File

SOURCE=..\..\src\module\wificrc.c
# End Source File
# Begin Source File

SOURCE=..\..\src\module\wificrc.h
# End Source File
# End Group
# Begin Group "stack"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\..\src\parser\arp.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\atalkddp.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\ethernet.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\gre.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\icmp.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\ieee8021x.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\igmp.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\ip.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\ipv6.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\layer1.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\novellipx.c
# End Source File
# Begin Source File

SOURCE=..\..\src\netstack\stackymsg.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\tcp.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\tcp.h
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\udp.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\wifi80211.c
# End Source File
# End Group
# Begin Group "stream"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\..\src\parser\aimoscar.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\http.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\http.h
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\httpcookie.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\httpform.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\httprsp.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\msnms.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\pop3.c
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\smtp.c
# End Source File
# End Group
# Begin Source File

SOURCE=..\..\src\crypto\des.c
# End Source File
# Begin Source File

SOURCE=..\..\src\main\ferret.c
# End Source File
# Begin Source File

SOURCE=..\..\src\include\ferret.h
# End Source File
# Begin Source File

SOURCE=..\..\src\main\jotdown.c
# End Source File
# Begin Source File

SOURCE=..\..\src\include\jotdown.h
# End Source File
# Begin Source File

SOURCE=..\..\src\main\main.cpp
# End Source File
# Begin Source File

SOURCE=..\..\src\include\parser.h
# End Source File
# Begin Source File

SOURCE=..\..\src\module\tcpchecksum.c
# End Source File
# Begin Source File

SOURCE=..\..\src\module\tcpchecksum.h
# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl"
# Begin Source File

SOURCE=..\..\src\parser\asn1.h
# End Source File
# Begin Source File

SOURCE="..\..\..\..\..\Prog\Microsoft - Visual Studio 6\VC98\Include\BASETSD.H"
# End Source File
# Begin Source File

SOURCE=..\..\src\parser\dns.h
# End Source File
# Begin Source File

SOURCE=..\..\src\include\formats.h
# End Source File
# Begin Source File

SOURCE=..\..\src\module\hamster.h
# End Source File
# Begin Source File

SOURCE=..\..\src\module\hexval.h
# End Source File
# Begin Source File

SOURCE=..\..\src\module\md5rfc1321.h
# End Source File
# Begin Source File

SOURCE=..\..\src\include\netframe.h
# End Source File
# Begin Source File

SOURCE=..\..\src\include\platform.h
# End Source File
# Begin Source File

SOURCE=..\..\src\include\template.h
# End Source File
# Begin Source File

SOURCE=..\..\src\module\val2string.h
# End Source File
# End Group
# Begin Source File

SOURCE=..\..\..\module
# End Source File
# End Target
# End Project
