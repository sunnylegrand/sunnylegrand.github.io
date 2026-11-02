# EasyEdit Mac 版

手机剪视频网页 App 的 Mac 本地运行版。剪辑引擎（FFmpeg.wasm）在首次运行时自动下载到本地，之后完全离线使用；视频只在你的 Mac 本机处理，不上传到任何服务器。

## 安装（推荐：用 Git）

```bash
# 第一次：克隆整个站点代码
git clone https://github.com/sunnylegrand/sunnylegrand.github.io.git
cd sunnylegrand.github.io/easyedit-mac

# 以后更新：进目录后拉一下就行
git pull
```

不用 Git 也行：从[站点代码 ZIP](https://github.com/sunnylegrand/sunnylegrand.github.io/archive/refs/heads/main.zip)下载解压，用里面的 `easyedit-mac` 文件夹。

## 运行

```bash
bash 启动EasyEdit.command
```

也可以直接双击 `启动EasyEdit.command`。如果 macOS 提示"无法验证开发者"：右键点击它 → 打开 → 在弹出框里再点"打开"，只需一次。

终端显示启动信息后，浏览器会自动打开 EasyEdit（http://localhost:8901/）。

## 说明

- 首次运行会自动下载剪辑引擎（约 32MB，需联网一次），下载到 `vendor/` 目录；之后断网也能用。
- 每次用双击/运行脚本即可；用完关闭终端窗口即停止服务。
- 不要删除或改名 `index.html` / `vendor`，那是 App 本体和引擎。
- 推荐 Chrome 或 Edge，Safari 也可用。
- 功能与线上版完全一致（含字幕、SRT 导入导出）。
