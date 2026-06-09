# Changelog

## v1.0 (2026-06-09) - 首次发布

### 内核功能
- **ReSukiSU v4.1.0** — 基于 syscall table hook + tracepoint hook 的 root 方案
- **SuSFS v2.1.00** — 文件/进程隐藏框架（hide packages, mount namespace, deny list）
- **BBR v1** — TCP 拥塞控制算法，比 Cubic 快 10-30%
- **FQ_CODEL** — 公平队列拥塞控制，降低延迟
- **ipset** — 高性能 IP 集合过滤
- **BBG** — Baseband Guard 基带安全防护
- **LZ4KD** — LZ4 压缩算法优化版（从 5.10 移植到 4.19）
- **NTSYNC** — NT 同步原语（Wine/Proton 兼容）
- **Docker** — 容器化支持（namespace, cgroup, overlayfs）
- **零宽绕过修复** — fs/unicode 补丁
- **GPU 频率优化** — 10 档频率表（515/380 MHz 中间档）
- **调度器调参** — CFS 4ms, hispeed 80, WALT hist_size=3

### 已禁用
- **BBRv2** — 与 4.19 TCP API 不兼容，需单独适配

### 硬件支持
- OnePlus 6 (Enchilada) / OnePlus 6T (Fajita)
- SDM845 SoC
- 完整 16 个 DTBO 覆盖层（11 enchilada + 5 fajita）
- Image.gz-dtb 压缩内核

### 两个版本
- **Standard** — CPU Boost 开启，触摸响应快
- **PowerSave** — 关 CPU Boost + PM Autosleep + Adreno TZ + Step Wise Thermal

### 工具与支持
- AnyKernel3 刷机框架
- OxygenOS Stock Recovery 兼容签名（jarsigner）
- VBMeta Disable Verification 工具（arm64-v8a）
- AK3 工具完整：busybox, magiskboot, magiskpolicy, lptools, httools, fec

### 支持管理器
- ReSukiSU Manager（官方推荐）
- KernelPatch
- SukiSU Ultra
- KOWSU

### 修复
- 修复 boot 分区溢出（47MB → 21MB 压缩）
- 修复 "Failed to find update binary" 错误（jarsigner 签名）
- 修复 dtbo.img 缺失问题
- 修复 SuSFS 缺失宏定义和函数声明
- 修复 netfilter 模块编译错误
- 修复 Windows 大小写不敏感导致文件冲突
