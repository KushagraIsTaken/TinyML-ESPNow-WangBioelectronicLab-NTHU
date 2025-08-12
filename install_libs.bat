@echo off
setlocal

REM === Arduino Libraries Folder ===
set "LIB_DIR=%USERPROFILE%\Documents\Arduino\libraries"

REM === Create Arduino libraries folder if it doesn't exist ===
if not exist "%LIB_DIR%" (
    echo Creating Arduino libraries folder...
    mkdir "%LIB_DIR%"
)

REM === Source folder is /libraries in this repo ===
set "SRC=%~dp0libraries"

if not exist "%SRC%" (
    echo ERROR: 'libraries' folder not found in this repo.
    pause
    exit /b 1
)

echo Installing libraries from: %SRC%
echo Target: %LIB_DIR%

REM === Loop through each subfolder in libraries ===
for /D %%L in ("%SRC%\*") do (
    set "FOLDERNAME=%%~nxL"
    echo.
    echo Installing %%~nxL ...
    if exist "%LIB_DIR%\%%~nxL" (
        echo Removing old version...
        rmdir /s /q "%LIB_DIR%\%%~nxL"
    )
    xcopy "%%L" "%LIB_DIR%\%%~nxL" /E /I /Y >nul
)

echo.
echo ✅ All libraries installed successfully!
pause
