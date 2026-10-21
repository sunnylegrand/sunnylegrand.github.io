@echo off
chcp 65001 >nul
cd /d %~dp0
title ColoRight Desktop
py -3 coloright_server.py 2>nul
if %errorlevel% equ 0 goto end
python coloright_server.py 2>nul
if %errorlevel% equ 0 goto end
echo.
echo ============================================
echo  没有找到 Python，ColoRight 桌面版需要 Python 才能启动。
echo  请到 https://www.python.org/downloads/ 下载安装，
echo  安装时记得勾选 "Add python.exe to PATH"。
echo  装好后重新双击本文件即可。
echo ============================================
pause
:end
