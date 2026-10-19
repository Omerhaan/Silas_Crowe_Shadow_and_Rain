@echo off
setlocal
title Golge ve Yagmur
cd /d "%~dp0"

echo ========================================================
echo   GOLGE VE YAGMUR - Vaka 1: Karanlik Malikane
echo   Godot 4 baslatiliyor...
echo ========================================================
echo.

set "GODOT_BIN=%LOCALAPPDATA%\Programs\Godot\godot.exe"

if not exist "%GODOT_BIN%" (
    if exist "%LOCALAPPDATA%\Programs\Godot\Godot_v4.3-stable_win64.exe" (
        set "GODOT_BIN=%LOCALAPPDATA%\Programs\Godot\Godot_v4.3-stable_win64.exe"
    ) else (
        set "GODOT_BIN=godot"
    )
)

"%GODOT_BIN%" --path .

endlocal
