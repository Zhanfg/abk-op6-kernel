# Changelog

## v1.0 (2026-06-09) - 首次发布

### 内核功能
- **ReSukiSU v4.1.0** — 基于 syscall table hook + tracepoint hook 的 root 方案
- **SuSFS v2.1.00** — 文件/进程隐藏框架（hide packages, mount namespace, deny list）
- **BBR v2** — TCP 拥塞控制算法
- **BBRv2** — 改进低带宽场景
- **ipset** — 高性能 IP 集合过滤
- **BBG** — 块设备 Buffer Layer 增强
- **LZ4KD** — LZ4 压缩算法优化版
- **NTSYNC** — NT 同步原语（Wine/Proton 兼容）
- **Docker** — 容器化支持

### 硬件支持
- OnePlus 6 (Enchilada) / OnePlus 6T (Fajita)
- SDM845 SoC
- 完整 16 个 DTBO 覆盖层（11 enchilada + 5 fajita）
- Image.gz-dtb 压缩内核（21MB）

### 两个版本
- **Standard** — CPU Boost 开启，触摸响应快
- **PowerSave** — 关 CPU Boost、PM Autosleep、Adreno TZ、Step Wise Thermal

### 工具与支持
- AnyKernel3 刷机框架
- OxygenOS Stock Recovery 兼容签名（jarsigner）
- VBMeta Disable Verification 工具（arm64-v8a）
- AK3 工具完整：busybox, magiskboot, magiskpolicy, lptools, httools, fec

### 支持管理器
- ReSukiSU Manager（官方）
- KernelPatch
- SukiSU Ultra
- KOWSU
- MKSU
- RKSU

### 修复
- 修复 boot 分区溢出（47MB → 21MB 压缩）
- 修复 "Failed to find update binary" 错误（jarsigner 签名）
- 修复 dtbo.img 缺失问题
- 修复 CPU Boost 误触导致耗电

### 已知问题
- 暂无
