#!/bin/bash
# EasyEdit Mac 版启动器
# 首次运行会自动下载剪辑引擎（约 32MB），之后完全离线使用
cd "$(dirname "$0")"
PORT=8901

ENGINE_DIR="vendor"
BASE1="https://cdn.jsdelivr.net/npm"
BASE2="https://unpkg.com"
FILES=(
  "@ffmpeg/ffmpeg@0.12.10/dist/umd/ffmpeg.js"
  "@ffmpeg/ffmpeg@0.12.10/dist/umd/814.ffmpeg.js"
  "@ffmpeg/util@0.12.1/dist/umd/index.js"
  "@ffmpeg/core@0.12.6/dist/umd/ffmpeg-core.js"
  "@ffmpeg/core@0.12.6/dist/umd/ffmpeg-core.wasm"
)
WASM_MIN=30000000  # 30MB，小于此视为没下全

need_dl=0
for f in "${FILES[@]}"; do
  if [ ! -s "$ENGINE_DIR/$f" ]; then need_dl=1; break; fi
done
if [ -f "$ENGINE_DIR/@ffmpeg/core@0.12.6/dist/umd/ffmpeg-core.wasm" ]; then
  sz=$(stat -f%z "$ENGINE_DIR/@ffmpeg/core@0.12.6/dist/umd/ffmpeg-core.wasm" 2>/dev/null || echo 0)
  if [ "$sz" -lt "$WASM_MIN" ]; then need_dl=1; fi
fi

if [ "$need_dl" -eq 1 ]; then
  echo "首次运行：正在下载剪辑引擎（约 32MB，只需一次）..."
  for f in "${FILES[@]}"; do
    dest="$ENGINE_DIR/$f"
    if [ -s "$dest" ] && [ "$f" != "@ffmpeg/core@0.12.6/dist/umd/ffmpeg-core.wasm" ]; then continue; fi
    if [ "$f" = "@ffmpeg/core@0.12.6/dist/umd/ffmpeg-core.wasm" ] && [ -s "$dest" ]; then
      sz=$(stat -f%z "$dest" 2>/dev/null || echo 0)
      if [ "$sz" -ge "$WASM_MIN" ]; then continue; fi
    fi
    mkdir -p "$(dirname "$dest")"
    ok=0
    for base in "$BASE1" "$BASE2"; do
      echo "下载 $f ..."
      if curl -L --fail --progress-bar -o "$dest.tmp" "$base/$f" 2>&1; then
        mv "$dest.tmp" "$dest"; ok=1; break
      else
        echo "这个源没连上，换备用源试试..."
        rm -f "$dest.tmp"
      fi
    done
    if [ $ok -eq 0 ]; then
      echo ""
      echo "下载失败：$f"
      echo "请检查网络后重新运行本脚本。"
      exit 1
    fi
  done
  echo "引擎下载完成，以后不再需要联网。"
  echo ""
fi

if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
  PORT=8902
fi

echo "正在启动 EasyEdit..."
echo "浏览器会自动打开 http://localhost:$PORT/"
echo "用完后直接关闭这个终端窗口即可停止服务。"
echo ""

(sleep 1 && open "http://localhost:$PORT/") &
exec python3 -m http.server $PORT --bind 127.0.0.1
