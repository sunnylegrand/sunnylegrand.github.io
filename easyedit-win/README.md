# EasyEdit Windows 版

手机剪视频网页 App 的 Windows 本地运行版。剪辑引擎（FFmpeg.wasm）在首次运行时自动下载到本地，之后完全离线使用；视频只在你的电脑本机处理，不上传到任何服务器。

## 安装（推荐：用 Git）

```bat
:: 第一次：克隆整个站点代码
git clone https://github.com/sunnylegrand/sunnylegrand.github.io.git
cd sunnylegrand.github.io\easyedit-win

:: 以后更新：进目录后拉一下就行
git pull
```

不用 Git 也行：从[站点代码 ZIP](https://github.com/sunnylegrand/sunnylegrand.github.io/archive/refs/heads/main.zip)下载解压，用里面的 `easyedit-win` 文件夹。

## 运行

双击 `启动EasyEdit.bat` 即可。

- 如果 Windows 显示 SmartScreen 警告（"已阻止无法识别的应用"）：点"更多信息" → "仍要运行"，只需一次。
- 首次运行会自动下载剪辑引擎（约 32MB，需联网一次），下载到 `vendor/` 目录；之后断网也能用。
- 黑窗口不要关：它就是本地服务。浏览器会自动打开 EasyEdit（http://127.0.0.1:8901/）。
- 用完直接关闭黑窗口即可。

## 说明

- 不要删除或改名 `index.html` / `vendor` / `Start-EasyEdit.ps1`，那是 App 本体、引擎和启动脚本。
- 需要 Windows 10 或更高版本（自带 curl）。推荐 Chrome 或 Edge。
- 功能与线上版完全一致（含字幕、SRT 导入导出）。
