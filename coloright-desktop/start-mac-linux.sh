#!/bin/sh
# ColoRight 桌面版启动脚本（macOS / Linux）
cd "$(dirname "$0")" || exit 1
exec python3 coloright_server.py
