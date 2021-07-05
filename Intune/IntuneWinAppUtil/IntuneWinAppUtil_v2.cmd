:begin
set /p App="AppName: "
set /p Setup="Setup: "
IF NOT EXIST "%~Dp0_Packages" (mkdir "%~Dp0_Packages")
IF NOT EXIST "%~Dp0_Icons" (mkdir "%~Dp0_Icons")

 %~Dp0IntuneWinAppUtil.exe -c %~Dp0%App% -s %Setup% -o %~Dp0Packages
:setretry
set /p retry="Try again (Y / N) ? "


IF /I %retry% == Y GOTO:begin
IF /I %retry% == N (exit) ELSE (GOTO:setretry)

