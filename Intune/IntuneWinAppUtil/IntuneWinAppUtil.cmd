set /p App="AppName: "
set /p Setup="Setup: "
"%~Dp0IntuneWinAppUtil.exe" -c "%~Dp0%App%" -s "%Setup%" -o "%~Dp0Packages"