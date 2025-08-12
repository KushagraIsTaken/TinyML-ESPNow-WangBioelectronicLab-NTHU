@echo off
setlocal

REM === Arduino Libraries Folder ===
set "LIB_DIR=%USERPROFILE%\Documents\Arduino\libraries"

REM === Create Libraries Folder if it Doesn't Exist ===
if not exist "%LIB_DIR%" (
    echo Arduino libraries folder not found. Creating...
    mkdir "%LIB_DIR%"
)

REM === Source Folder is Where This .bat is Located ===
set "SRC=%~dp0"

echo Installing all libraries from: %SRC%
echo Target folder: %LIB_DIR%

REM === Loop Through Each Subfolder (Library) ===
for /D %%L in ("%SRC%*") do (
    set "FOLDERNAME=%%~nxL"
    REM Skip if this is the batch file directory itself (like .git or other extras)
    if not "%%~nxL"=="install_libs.bat" (
        echo.
        echo Installing library: %%~nxL
        if exist "%LIB_DIR%\%%~nxL" (
            echo Removing old version...
            rmdir /s /q "%LIB_DIR%\%%~nxL"
        )
        xcopy "%%L" "%LIB_DIR%\%%~nxL" /E /I /Y >nul
    )
)

echo.
echo ✅ All libraries installed successfully!
pause
