@echo off
cd /d %~dp0
title ColoRight Desktop
py -3 coloright_server.py 2>nul
if %errorlevel% equ 0 goto end
python coloright_server.py 2>nul
if %errorlevel% equ 0 goto end
echo.
echo ============================================
echo  Python was not found on this PC.
echo  ColoRight Desktop needs Python to start.
echo  Download it from https://www.python.org/downloads/
echo  and tick "Add python.exe to PATH" during setup,
echo  then double-click this file again.
echo ============================================
pause
:end
