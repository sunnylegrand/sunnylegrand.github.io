# ColoRight 桌面版

在自己电脑上用的修图软件：修图功能和 ColoRight网页版同源（预设、光影、色彩、曲线、HSL、效果、细节、裁剪旋转、智能消除、撤销/重做、原图分辨率导出），AI部分不再用浏览器里的小模型，改为连接**你电脑上的 ComfyUI**，用你装好的本地大模型干活：

- **AI 抠图**：用 BiRefNet / RMBG 类节点抠出主体（透明底），可一键换白底
- **生成背景**：用 Z-Image 按文字生成背景，已抠图时自动把主体合成到新背景上
- **消除重绘**：涂抹区域交给绘图大模型按周围画面重新生成（比本地快速修复自然）
- **AI 放大**：用放大模型放大 2 倍并补细节
- **美化重绘**：整图图生图轻度重绘，去噪点、补细节
- **自定义工作流**：任意 ComfyUI 工作流导出 API 格式 JSON 就能接进来跑

所有照片只在本机和你的 ComfyUI 之间流转，不经过任何外部服务器。

## 怎么用

### 1. 准备

- **Python 3**（只用自带库，不用装任何包）
  - Windows：到 https://www.python.org/downloads/ 安装，安装时勾选 “Add python.exe to PATH”；或在微软商店搜 Python 安装
  - macOS / Linux：系统一般自带 `python3`，没有就按系统方式安装
- **ComfyUI**：已装好并能正常打开界面；用 AI 功能时保持它开着（默认地址 `http://127.0.0.1:8188`）

### 2. 启动

- Windows：双击 `start-windows.bat`
- macOS / Linux：终端里运行 `sh start-mac-linux.sh`

启动后会打开一个小窗口（本地服务，别关），浏览器自动打开编辑器。顶部状态点变绿 = 已连上 ComfyUI。用完关掉那个小窗口即可。

> 注意：直接双击 `index.html` 打开也能修图，但浏览器会拦截网页连接本机 ComfyUI，AI 功能用不了——AI 必须经启动器打开。

### 3. 各 AI 功能需要什么

| 功能 | 需要的东西（放在 ComfyUI 对应目录后，点应用内「刷新模型列表」） |
|---|---|
| 抠图 | LayerStyle 抠图节点 RmBgUltra V2 + 权重文件 model.pth（约 170MB，来自 Hugging Face 的 briaai/RMBG-1.4，手动放进 `custom_nodes\ComfyUI_LayerStyle\RMBG-1.4\`）；细节处理默认 GuidedFilter，纯本地计算、不联网下载 |
| 生成背景 | Z-Image 三件套：扩散模型（如 `z_image_turbo_bf16.safetensors`，放 `models/diffusion_models/`）、文本编码器（`qwen_3_4b.safetensors`，放 `models/text_encoders/`）、VAE（`ae.safetensors`，放 `models/vae/`）。也可以在 ComfyUI 模板里一键装 Z-Image 工作流，它会自动下载 |
| 消除重绘 | Flux.2-Klein-4B 扩散模型 + Qwen3-4B 文本编码器（CLIP 类型选 flux2）+ Flux2 VAE，走局部重绘采样链 |
| 美化重绘 | Qwen Image Edit 扩散模型（如 2509/2511）+ Qwen2.5-VL 文本编码器 + Qwen Image VAE，按文字指令整图编辑 |
| 放大 | 放大模型（ESRGAN / RealESRGAN 类 `.pth`，放 `models/upscale_models/`） |

显存参考：Z-Image BF16 约需 14–16GB，FP8 版约 6–8GB；占用以实际模型为准。

## 工作流模板

AI 页底部有「工作流模板（可改）」：内置模板按最常见的节点结构写（占位符 `__IMAGE__`、`__PROMPT__`、`__MODEL__` 等运行时自动替换）。你的节点结构和模板对不上时，有两个办法：

1. 直接改模板 JSON 后保存（存在浏览器本地，下次还在）
2. 用「高级：自定义工作流」：在 ComfyUI 里把你调好的工作流导出为 **API 格式** JSON，粘贴进来，填图片节点和提示词节点的编号即可运行

任务执行前会自动检查工作流里的节点在你的 ComfyUI 里是否存在，缺哪个会直接报出节点名，不会闷头失败。

## 常见问题

- **顶部一直显示未连接**：确认 ComfyUI 已启动且浏览器能打开它的界面；地址栏改成你的 ComfyUI 实际地址后点「测试连接」。ComfyUI 若改过端口（不是 8188），地址要跟着改。
- **抠图按钮提示没有节点**：先装抠图节点包（见上表），重启 ComfyUI，再回应用点「刷新模型列表」。
- **生成很慢**：视频/大图任务本身就吃显卡；界面会显示排队位置和已用时间，可随时取消（取消会同时中断 ComfyUI 里的当前任务）。
- **换了电脑/浏览器后模板没了**：模板和连接地址存在浏览器本地存储里，换环境后重新粘贴一次即可。
- **GitHub Pages 上打开的 ColoRight桌面版页面**：那只是同一份文件的在线预览，AI 连不上本机 ComfyUI（浏览器安全限制），请以下载到本地、经启动器打开的为准。

## 文件说明

- `index.html` — 编辑器本体（修图 + AI 面板）
- `coloright_server.py` — 本地启动服务：打开页面 + 转发 `/comfy/*` 到本机 ComfyUI（解决浏览器跨域拦截）
- `start-windows.bat` / `start-mac-linux.sh` — 一键启动
