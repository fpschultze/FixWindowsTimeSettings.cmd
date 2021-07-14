@ECHO OFF

SET 2ndCall=%1
SET tmpFolder=%TEMP%\%~n0
SET tmpFile=%tmpFolder%\output-%RANDOM%.tmp
SET TypeShouldBe=NT5DS
(SET TypeCurrent=)

MKDIR %tmpFolder% 2>NUL

ECHO Check type of time server...
w32tm.exe /query /configuration | findstr.exe /B /C:"Type:" >%tmpFile%
FOR /F "tokens=2 delims=: " %%i IN (%tmpFile%) DO (SET TypeCurrent=%%i)
IF NOT DEFINED TypeCurrent (
  ECHO ERROR: Failed to get time server type
  GOTO :End
)

IF %TypeCurrent% EQU %TypeShouldBe% (
  ECHO Type of time server is ok - %TypeShouldBe%
  GOTO :End
)

ECHO Type of time server is not ok - "%TypeShouldBe%"
IF DEFINED 2ndCall GOTO :End
CALL :FixW32Time
ECHO Checking again...
%~dpnx0 AfterFix

:End
RMDIR /S /Q %tmpFolder%
GOTO :EOF

:FixW32Time
  ECHO Fixing the time service to get its time from the Active Directory...
  w32tm.exe /config /syncfromflags:domhier /update

  ECHO Restart Time Service...
  net.exe STOP w32time && sc.exe START w32time
  ping.exe -n 20 localhost > NUL 2>&1

  ECHO Tell the system to update its time...
  w32tm.exe /resync /rediscover
GOTO :EOF
