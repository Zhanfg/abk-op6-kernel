# ABK OnePlus 6 Kernel - ReSukiSU + SuSFS v2.1.00

OnePlus 6 (Enchilada/SDM845) Android 4.19 自定义内核，支持 OxygenOS / DerpFest / LineageOS。

## 内置功能

| 功能 | 版本 | 说明 |
|------|------|------|
| **ReSukiSU** | v4.1.0 | 基于 syscall table hook + tracepoint hook 的完整 root 方案 |
| **SuSFS** | v2.1.00 | 文件/进程隐藏框架，支持 deny list、hide packages、mount namespace |
| **BBR** | v1 | TCP 拥塞控制算法，比 Cubic 快 10-30% |
| **ipset** | — | 高性能 IP 集合过滤，配合 iptables/nftables |
| **FQ_CODEL** | — | 公平队列拥塞控制，降低延迟 |
| **BBG** | — | Baseband Guard 基带安全防护 |
| **LZ4KD** | — | LZ4 压缩算法优化版，加快 zram/ramdisk 解压 |
| **NTSYNC** | — | NT 同步原语支持（Wine/Proton 游戏兼容层） |
| **Docker** | — | 容器支持（namespace、cgroup、overlayfs） |
| **零宽绕过修复** | — | fs/unicode 补丁，修复零宽字符检测绕过 |
| **GPU 频率优化** | — | 10 档频率表（515/380 MHz 中间档） |
| **调度器调参** | — | CFS 4ms, hispeed 80, WALT hist_size=3 |

> ⚠️ **BBRv2 已禁用** — 与 4.19 TCP API 不兼容，需单独适配

## 支持管理器

- ✅ **ReSukiSU Manager** — 官方推荐，支持所有 SuSFS 功能
- ✅ **KernelPatch** — 通过 KernelPatch 适配
- ✅ **SukiSU Ultra** — 兼容模式
- ✅ **KOWSU** — 兼容模式

## 两种版本

### Standard（标准版）
- CPU 默认使用 **Schedutil** 调频器
- **CPU Boost 开启**（触摸瞬间拉频，响应更快）
- 适合追求性能的用户

### PowerSave（省电版）
- CPU 默认使用 **Schedutil** 调频器
- **CPU Boost 关闭**（平滑调频，省电）
- **PM Autosleep 开启**（灭屏深度休眠）
- **Workqueue 省电模式**（降低后台 CPU 唤醒）
- **Wakelocks GC**（清理泄漏的 wakelock）
- **GPU Adreno TZ**（GPU 空闲自动降频）
- **Thermal Step Wise**（温控更平滑降频）
- 适合追求续航的用户

## 硬件信息

| 项目 | 参数 |
|------|------|
| 设备 | OnePlus 6 (Enchilada) |
| 芯片 | Qualcomm SDM845 |
| 架构 | ARM64 (AArch64) |
| 内核版本 | 4.19.x |
| 编译器 | Clang/LLVM + GCC cross-compile |
| 内核格式 | `Image.gz-dtb`（压缩格式，适配 boot 分区） |
| DTBO | 完整 16 个覆盖层（enchilada 11 + fajita 5），`mkdtboimg` 格式 |

## ZIP 结构

```
ABK_OnePlus6_ReSukiSU_SuSFS210_*.zip
├── Image.gz-dtb          # 内核 + DTB（压缩）
├── dtbo.img              # DTB 覆盖层镜像（16 overlays）
├── anykernel.sh          # AnyKernel3 刷机脚本
├── LICENSE
├── README.md
├── META-INF/
│   └── com/google/android/
│       ├── update-binary   # 刷机入口
│       └── updater-script  # 版本检查
├── tools/
│   ├── ak3-core.sh        # AnyKernel3 核心
│   ├── busybox
│   ├── magiskboot
│   ├── magiskpolicy
│   ├── vbmeta-disable-verification  # vbmeta 禁用工具
│   ├── lptools_static
│   ├── httools_static
│   └── fec
├── modules/
├── patch/
└── ramdisk/
```

## 刷入方法

1. **OxygenOS Recovery**：重启到 recovery → Apply from storage → 选择 ZIP
2. **TWRP**：重启到 TWRP → Install → 选择 ZIP
3. **AB 分区设备**：`fastboot flash boot Image.gz-dtb` + `fastboot flash dtbo dtbo.img`

> 注意：ZIP 已签名（jarsigner），兼容 OxygenOS Stock Recovery

## 兼容性

- ✅ OxygenOS (Stock)
- ✅ DerpFest 16.x
- ✅ LineageOS 23.x
- ⚠️ 其他基于 LineageOS 的 ROM 需测试

## 编译方法

1. Fork 本仓库
2. 切换到 `main` 分支
3. 在 Actions 页面手动运行 `Build Standard` 或 `Build PowerSave`
4. 编译完成后下载 Artifact

## Changelog

### v1.0 (2026-06-09)
- 首次发布
- ReSukiSU v4.1.0 + SuSFS v2.1.00
- 完整 BBR/FQ_CODEL/ipset/BBG/LZ4KD/NTSYNC/Docker 支持
- 标准版 + 省电版双版本
- OxygenOS Recovery 兼容签名
- 完整 DTBO 支持（16 overlays, enchilada + fajita）
- VBMeta Disable Verification 工具

## 许可证

- 内核源码：GPL-2.0
- AnyKernel3：MIT
- vbmeta-disable-verification：Apache-2.0
