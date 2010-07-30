@echo off
rem rc.bat - robocopy wrapper (simple backup script for system drive)

setlocal
  set BackupDirs=\\ComputerName\ShareName\rc;c:\rc;d:\rc;e:\rc;f:\rc;g:\rc
  set RobocopyOptions=/MIR /XO /NP /V /R:1 /W:3 /FFT /DCOPY:T
  set EnableExclude=yes
  set ExcludeFiles=*ntuser.dat* UsrClass.dat* Perflib_*.dat *swap.img
  set ExcludeDirs=Cache Temp "Temporary Internet Files"
  set EnableVerbose=no
  set EnableLog=yes
  set EnableDebug=no
  rem ----------END OF CONFIG----------
  set MYNAME=rc
  set Version=0.4.1
  for %%i in (%BackupDirs%) do if exist %%i set DEST=%%i
  call :sub_set_datetime
  call :sub_set_robocopy_option
  if "%1"=="/new" call :sub_new %DEST% && goto END
  if exist "%1" if exist "%2" call :sub_simple %1 %2 && goto END
  if exist "%1" call :sub_batch %DEST% "%1" && goto END
  if "%1"=="" call :sub_batch %DEST% && goto END
  :END
endlocal
exit /b 0

:sub_set_datetime
  set DATETIME=%date:/=-%-%time::=-%
  set DATETIME=%DATETIME:~0,16%
  set DATETIME=%DATETIME: =0%
exit /b 0

:sub_set_robocopy_option
  set ROBO_LIST=robocopy.exe;%SystemRoot%\system32\robocopy.exe
  for %%i in (%ROBO_LIST%) do if exist %%i set ROBO=%%i
  if "%ROBO%"=="" set ROBO=robocopy.exe
  set LOG=%MYNAME%-%DATETIME%.log
  set OPT=%RobocopyOptions%
  if "%EnableExclude%"=="yes" set OPT=%OPT% /XF %ExcludeFiles%
  if "%EnableExclude%"=="yes" set OPT=%OPT% /XD %ExcludeDirs%
  if "%EnableVerbose%"=="yes" set OPT=%OPT% /TEE
  if "%EnableLog%"=="yes" set OPT=%OPT% /LOG+:%LOG%
exit /b 0

:sub_new
  set DST=%~1\%COMPUTERNAME%
  if exist "%DST%" move "%DST%" "%DST%-%DATETIME%" > NUL
exit /b 0

:sub_simple
  echo SRC: %1
  echo DST: %2
  echo %ROBO% %1 %2 %OPT%
  %ROBO% %1 %2 %OPT% > NUL 2>&1
exit /b 0

:sub_copy_folders
  set INI=%CD%\rc.ini
  if exist %CD%\rc_%COMPUTERNAME%.ini set INI=%CD%\rc_%COMPUTERNAME%.ini
  if not exist %INI% echo %INI% is not found && exit /b 0
  echo INFO: %INI%
  FOR /F "tokens=1,2 delims=," %%a IN (%INI%) DO (
    if "%%b"=="" call :sub_robocopy "%%a"
    if not "%%b"=="" if exist "%%b" call :sub_simple "%%a" "%%b"
    if not "%%b"=="" if not exist "%%b" echo "%%b is not exist. skip."
  )
exit /b 0

:sub_batch
  set DST=%~1\%COMPUTERNAME%
  set SRC=%~2
  %ROBO% > NUL 2>&1
  if not "%ERRORLEVEL%"=="0" echo %ROBO% is not found && exit /b 1
  if "%USERPROFILE%"=="" exit /b 1
  mkdir "%DST%" > NUL 2>&1
  echo INFO: %DST%
  echo INFO: %ROBO%
  echo INFO: %LOG%
  if exist "%SRC%" call :sub_robocopy %2
  if not exist "%SRC%" call :sub_copy_folders
  if not exist %LOG% goto _no_log
    move %LOG% "%DST%" >NUL
    find "ERROR:" "%DST%\%LOG%" > "%DST%\\%LOG%.err"
    if not "%ERRORLEVEL%"=="0" del "%DST%\%LOG%.err"
    if exist "%DST%\%LOG%.err" start notepad.exe "%DST%\%LOG%.err"
  :_no_log
exit /b 0

:sub_robocopy
  if not exist %1 echo SKIP: %1
  if not exist %1 exit /b 1
  echo COPY: %1
  if "%EnableDebug%"=="yes" echo DEBUG: %ROBO% %1 "%DST%\%~n1" %OPT%
  if "%EnableVerbose%"=="yes" %ROBO% %1 "%DST%\%~n1" %OPT% && goto _Verbose
    %ROBO% %1 "%DST%\%~n1" %OPT% > NUL 2>&1
  :_Verbose
exit /b 0
