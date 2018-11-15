@echo off
setlocal EnableDelayedExpansion
rem Windows BAT/CMD
rem NSClient++ plugin for 1C Enterpise cluster check via Remote administration server
rem @andru 15/11/2018

rem Options:
rem   -H:NAME       hostname to connect to; defaults to localhost
rem   -N:NUM        port to connect to; defaults to 1545
rem   -C:CMD        command to check; defaults to cluster
rem   -I:NAME       optional, information database name, use with --command=infobase
rem   -U:USERNAME   optional, --cluster-user=USERNAME, cluster administrator username
rem   -P:USERPWD    optional, --cluster-pwd=USERPWD, cluster administrator password
rem   -A:USERNAME   optional, --infobase-user=USERNAME, infobase administrator username
rem   -S:USERPWD    optional, --infobase-pwd=USERPWD, infobase administrator password
rem  commands list:
rem     cluster    - check cluster available,
rem     server     - check number of servers,
rem     process    - check number of working processes,
rem     session    - check number of active sessions,
rem     license    - check number of used licenses,
rem     connection - check number of active connections,
rem     infobase   - check number of infobases,
rem                  new sessions deny state and scheduled jobs deny state with -i parameter

rem path to rac command
Set RAC="C:\Program Files\1cv8\8.3.10.2580\bin\rac"
Set tmpFile=%TEMP%\_check_1c.txt

if [%RAC%] == [] echo UNKNOWN - rac command not defined & exit %UNKNOWN%

rem plugin return codes
Set /A OK=0
Set /A WARNING=1
Set /A CRITICAL=3
Set /A UNKNOWN=4

rem parse script parameters:
rem  -H:host -N:port -C:command -I:infobase -U:cluster-user -P:cluster-pwd -A:infobase-user -S:infobase-pwd

:parse
if [%1] == [] goto start
for /f "tokens=1,* delims=:" %%a in ("%1") do set %%a=%%~b
shift
goto parse

:start

rem default values
Set host=localhost
Set port=1545
Set command=cluster

if not [%-H%] == [] Set host=%-H%
if not [%-N%] == [] Set port=%-N%
if not [%-C%] == [] Set command=%-C%
if not [%-I%] == [] Set infobase=%-I%
if not [%-U%] == [] Set cuser=%-U%
if not [%-P%] == [] Set cpwd=%-P%
if not [%-A%] == [] Set iuser=%-A%
if not [%-S%] == [] Set ipwd=%-S%

rem echo params: %host% %port% %command% %infobase% %cuser% %cpwd% %iuser% %ipwd%

if exist %tmpFile% del /f /q %tmpFile%
%RAC% cluster list %host%:%port% > %tmpFile% 2>nul
if not ERRORLEVEL 0 echo CRITICAL - connect error & exit %CRITICAL%

rem parse cluster variables: id, name
if exist %tmpFile% (
 for /f "tokens=1,2 delims=:" %%a in ('findstr /B /C:cluster %tmpFile%') do (
  for /f "tokens=1,2 delims= " %%A in ("%%a %%b") do (
   if [%%A] == [cluster] Set cluster-id=%%B
  )
 )
 for /f "tokens=1,2 delims=:" %%a in ('findstr /B /C:name %tmpFile%') do (
  for /f delims^=^"^ tokens^=1^,2 %%A in ("%%a %%b") do Set cluster-name="%%B"
 )
 del /f /q %tmpFile%
)

rem echo cluster: %cluster-id% %cluster-name%

if [%command%] == [cluster] (
 if [%cluster-id%] == [] echo CRITICAL - connect error & exit %CRITICAL%
 if not [%cluster-name%] == [] echo OK - %cluster-name% found & exit %OK%
 echo Unknown error & exit %UNKNOWN%
)

if [%command%] == [server] (
 if [%cluster-id%] == [] echo CRITICAL - connect error & exit %CRITICAL%
 if not [%cuser%] == [] (
  %RAC% server list --cluster=%cluster-id% --cluster-user=%cuser% --cluster-pwd=%cpwd% %host%:%port% > %tmpFile% 2>nul
 ) else (
  %RAC% server list --cluster=%cluster-id% %host%:%port% > %tmpFile% 2>nul
 )
 if not ERRORLEVEL 0 echo UNKNOWN - connect error or auth required & exit %UNKNOWN%
 Set /A cnt=0
 if exist %tmpFile% (
  for /f "tokens=2 delims=:" %%a in ('findstr /B /C:server %tmpFile%') do (
   Set /A cnt+=1 
  )
  del /f /q %tmpFile%
 )
 If !cnt! NEQ 0 echo OK - !cnt! server^(s^) found ^| servers^=!cnt! & exit %OK%
 echo CRITICAL - no working server^(s^) found & exit %CRITICAL%
)

if [%command%] == [process] (
 if [%cluster-id%] == [] echo CRITICAL - connect error & exit %CRITICAL%
 if not [%cuser%] == [] (
  %RAC% process list --cluster=%cluster-id% --cluster-user=%cuser% --cluster-pwd=%cpwd% %host%:%port% > %tmpFile% 2>nul
 ) else (
  %RAC% process list --cluster=%cluster-id% %host%:%port% > %tmpFile% 2>nul
 )
 if not ERRORLEVEL 0 echo UNKNOWN - connect error or auth required & exit %UNKNOWN%
 Set /A cnt=0
 if exist %tmpFile% (
  for /f "tokens=2 delims=:" %%a in ('findstr /B /C:process %tmpFile%') do (
   Set /A cnt+=1 
  )
  del /f /q %tmpFile%
 )
 If !cnt! NEQ 0 echo OK - !cnt! working process^(es^) found ^| processes=!cnt! & exit %OK%
 echo CRITICAL - no working process^(es^) found & exit %CRITICAL%
)

if [%command%] == [connection] (
 if [%cluster-id%] == [] echo CRITICAL - connect error & exit %CRITICAL%
 if not [%cuser%] == [] (
  %RAC% connection list --cluster=%cluster-id% --cluster-user=%cuser% --cluster-pwd=%cpwd% %host%:%port% > %tmpFile% 2>nul
 ) else (
  %RAC% connection list --cluster=%cluster-id% %host%:%port% > %tmpFile% 2>nul
 )
 if not ERRORLEVEL 0 echo UNKNOWN - connect error or auth required & exit %UNKNOWN%
 if exist %tmpFile% (
  Set /A cnt=0
  for /f "tokens=2 delims=:" %%a in ('findstr /B /C:process %tmpFile%') do (
   Set /A cnt+=1 
  )
  del /f /q %tmpFile%
 )
 echo OK - !cnt! connection^(s^) found ^| connections=!cnt! & exit %OK%
)

if [%command%] == [session] (
 if [%cluster-id%] == [] echo CRITICAL - connect error & exit %CRITICAL%
 if not [%cuser%] == [] (
  %RAC% session list --cluster=%cluster-id% --cluster-user=%cuser% --cluster-pwd=%cpwd% %host%:%port% > %tmpFile% 2>nul
 ) else (
  %RAC% session list --cluster=%cluster-id% %host%:%port% > %tmpFile% 2>nul
 )
 if not ERRORLEVEL 0 echo UNKNOWN - connect error or auth required & exit %UNKNOWN%
 if exist %tmpFile% (
  Set /A cnt=0
  for /f "tokens=2 delims=:" %%a in ('findstr /B /C:process %tmpFile%') do (
   Set /A cnt+=1 
  )
  del /f /q %tmpFile%
 )
 echo OK - !cnt! session^(s^) found ^| sessions=!cnt! & exit %OK%
)

if [%command%] == [license] (
 if [%cluster-id%] == [] echo CRITICAL - connect error & exit %CRITICAL%
 if not [%cuser%] == [] (
  %RAC% session list --licenses --cluster=%cluster-id% --cluster-user=%cuser% --cluster-pwd=%cpwd% %host%:%port% > %tmpFile% 2>nul
 ) else (
  %RAC% session list --licenses --cluster=%cluster-id% %host%:%port% > %tmpFile% 2>nul
 )
 if not ERRORLEVEL 0 echo UNKNOWN - connect error or auth required & exit %UNKNOWN%
 if exist %tmpFile% (
  Set /A cnt=0
  for /f "tokens=2 delims=:" %%a in ('findstr /B /C:session %tmpFile%') do (
   Set /A cnt+=1 
  )
  del /f /q %tmpFile%
 )
 echo OK - !cnt! license^(s^) found ^| licences=!cnt! & exit %OK%
)

if [%command%] == [infobase] (
 if [%infobase%] == [] (
  if [%cluster-id%] == [] echo CRITICAL - connect error & exit %CRITICAL%
  if not [%cuser%] == [] (
   %RAC% infobase summary list --cluster=%cluster-id% --cluster-user=%cuser% --cluster-pwd=%cpwd% %host%:%port% > %tmpFile% 2>nul
  ) else (
   %RAC% infobase summary list --cluster=%cluster-id% %host%:%port% > %tmpFile% 2>nul
  )
  if not ERRORLEVEL 0 echo UNKNOWN - connect error or auth required & exit %UNKNOWN%
  if exist %tmpFile% (
   Set /A cnt=0
   for /f "tokens=2 delims=:" %%a in ('findstr /B /C:infobase %tmpFile%') do (
    Set /A cnt+=1 
   )
   del /f /q %tmpFile%
  )
  echo OK - !cnt! infobase^(s^) found ^| infobases=!cnt! & exit %OK%
 ) else (
  if [%cluster-id%] == [] echo CRITICAL - connect error & exit %CRITICAL%
  if not [%cuser%] == [] (
   %RAC% infobase summary list --cluster=%cluster-id% --cluster-user=%cuser% --cluster-pwd=%cpwd% %host%:%port% > %tmpFile% 2>nul
  ) else (
   %RAC% infobase summary list --cluster=%cluster-id% %host%:%port% > %tmpFile% 2>nul
  )
  if not ERRORLEVEL 0 echo UNKNOWN - connect error or auth required & exit %UNKNOWN%
  set /A ibcnt=0
  if exist %tmpFile% (
   set /A cnt=1
   for /f "tokens=2 delims=: " %%a in ('findstr /B /C:name %tmpFile%') do (
    if [%%a] == [%infobase%] set /A ibcnt=!cnt!
    set /A cnt+=1
   )
  )
  if !ibcnt! EQU 0 echo CRITICAL - infobase %infobase% not found & exit %CRITICAL%
   if exist %tmpFile% (
   set /A cnt=1
    for /f "tokens=2 delims=: " %%a in ('findstr /B /C:infobase %tmpFile%') do (
     if [!ibcnt!] == [!cnt!] Set infobase-id=%%a
     set /A cnt+=1
    )
   )
   del /f /q %tmpFile%
   if [!infobase-id!] == [] echo CRITICAL - infobase %infobase% not found & exit %CRITICAL%
   if not [%cuser%] == [] (
    set cauth=--cluster-user=%cuser%^ --cluster-pwd=%cpwd%
   )
   if not [%iuser%] == [] (
    set iauth=--infobase-user=%iuser%^ --infobase-pwd=%ipwd%
   )
   %RAC% infobase info --cluster=%cluster-id% !cauth! --infobase=!infobase-id! !iauth! %host%:%port% > %tmpFile% 2>nul
   if not ERRORLEVEL 0 echo UNKNOWN - connect error or auth required & exit %UNKNOWN%
   if exist %tmpFile% (
    for /f "tokens=2 delims=: " %%a in ('findstr /B /C:scheduled-jobs-deny %tmpFile%') do (
     set scheduled-jobs-deny=%%a
    )
    for /f "tokens=2 delims=: " %%a in ('findstr /B /C:sessions-deny %tmpFile%') do (
     set sessions-deny=%%a
    )
    del /f /q %tmpFile%
   )
   if [scheduled-jobs-deny] == [on] echo CRITICAL - infobase %infobase% locked or scheduled jobs denied & exit %CRITICAL%
   if [sessions-deny] == [on] echo CRITICAL - infobase %infobase% locked or scheduled jobs denied & exit %CRITICAL%
   echo OK - infobase "%infobase%" is not locked & exit %OK%
 )
)
