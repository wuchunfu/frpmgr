@echo off
setlocal enabledelayedexpansion
for /F "delims=" %%i in (version) do (set FRPMGR_VERSION=%%i)
if [%FRPMGR_VERSION%]==[] set FRPMGR_VERSION=v0.0.0
set FRPMGR_VERSION=%FRPMGR_VERSION:~1%
echo Version: %FRPMGR_VERSION%
for /F "usebackq tokens=1,2 delims==" %%i in (`wmic os get LocalDateTime /VALUE 2^>NUL`) do if '.%%i.'=='.LocalDateTime.' set ldt=%%j
set BUILD_DATE=%ldt:~0,4%-%ldt:~4,2%-%ldt:~6,2%
echo Date: %BUILD_DATE%
set BUILDDIR=%~dp0
set PATH=%BUILDDIR%.deps;%PATH%
echo [+] Rendering icons
for %%a in ("icon\*.svg") do convert  -density 1000 -background none "%%~fa" -define icon:auto-resize="256,192,128,96,64,48,32,24,16" "%%~dpna.ico" || exit /b 1
echo [+] Building resources
windres -DFRPMGR_VERSION_ARRAY=%FRPMGR_VERSION:.=,% -DFRPMGR_VERSION_STR=%FRPMGR_VERSION% -i cmd/frpmgr/resources.rc -o cmd/frpmgr/rsrc.syso -O coff -c 65001 || exit /b %errorlevel%
echo [+] Downloading packages
go mod tidy || exit /b 1
echo [+] Patching files
for %%f in (patches\*.patch) do patch -N -r - -d %GOPATH% -p0 < %%f
echo [+] Compiling release version
set MOD=github.com/koho/frpmgr
set GO111MODULE=on
set CGO_ENABLED=0
for /F "tokens=2 delims=@" %%y in ('go mod graph ^| findstr %MOD% ^| findstr frp@') do (set FRP_VERSION=%%y)
go build -trimpath -ldflags="-H windowsgui -s -w -X %MOD%/pkg/version.Version=v%FRPMGR_VERSION% -X %MOD%/pkg/version.FRPVersion=%FRP_VERSION% -X %MOD%/pkg/version.BuildDate=%BUILD_DATE%" -o bin/frpmgr.exe ./cmd/frpmgr || exit /b 1
echo [+] Building installer
call installer/build.bat %FRPMGR_VERSION% || exit /b 1
echo [+] Success.
exit /b 0