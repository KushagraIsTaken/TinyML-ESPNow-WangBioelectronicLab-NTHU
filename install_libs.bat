::[Bat To Exe Converter]
::
::YAwzoRdxOk+EWAnk
::fBw5plQjdG8=
::YAwzuBVtJxjWCl3EqQJhSA==
::ZR4luwNxJguZRRmK4EolPxpaSwiDPgs=
::Yhs/ulQjdF+5
::cxAkpRVqdFKZSjk=
::cBs/ulQjdF+5
::ZR41oxFsdFKZSDk=
::eBoioBt6dFKZSDk=
::cRo6pxp7LAbNWATEpCI=
::egkzugNsPRvcWATEpSI=
::dAsiuh18IRvcCxnZtBJQ
::cRYluBh/LU+EWAnk
::YxY4rhs+aU+IeA==
::cxY6rQJ7JhzQF1fEqQJhZksaHGQ=
::ZQ05rAF9IBncCkqN+0xwdVs0
::ZQ05rAF9IAHYFVzEqQIROh9BRQqNfF+zCKwxxKjP4OWLqUQJNA==
::eg0/rx1wNQPfEVWB+kM9LVsJDGQ=
::fBEirQZwNQPfEVWB+kM9LVsJDGQ=
::cRolqwZ3JBvQF1fEqQJQ
::dhA7uBVwLU+EWDk=
::YQ03rBFzNR3SWATElA==
::dhAmsQZ3MwfNWATE31cjIBpTXgXCHWyoB6Id5Ig=
::ZQ0/vhVqMQ3MEVWAtB9wSA==
::Zg8zqx1/OA3MEVWAtB9wSA==
::dhA7pRFwIByZRRnk
::Zh4grVQjdCyDJGyX8VAjFBBBXwzWAES0A5EO4f7+086IoVgQUewra7P806CmNeIv3kzqbLsBm19pqOUDG1ZvfxysTAY7rGJHtXCXOMmVsCPgSAWn0mMFJ2x6lHfRgCc+cp1tgsZj
::YB416Ek+ZW8=
::
::
::978f952a14a936cc963da21a135fa983
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
