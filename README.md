# ABK OnePlus 6 Kernel

面向 **OnePlus 6（`enchilada` / SDM845）** 的 Linux 4.19 自定义内核构建与发布仓库。

> 当前项目已完成 CI 构建验证，但尚未完成完整真机运行时验证。刷入前必须准备当前 ROM 对应的原版 `boot.img`、可用的 Fastboot 环境和可靠回滚路径。

## 项目组成

| 仓库 | 作用 |
|---|---|
| `Zhanfg/abk-op6-kernel` | GitHub Actions、Standard / PowerSave 构建、AnyKernel3 打包、发布文档 |
| `Zhanfg/kernel_oneplus_sdm845` | OnePlus 6 SDM845 Linux 4.19 源码、自定义功能与上游基线记录 |

构建仓库默认读取源码仓库 `master` 分支，但每次运行都会先解析并固定具体源码提交 SHA，避免构建过程中分支发生漂移。

## 目标设备与基线

| 项目 | 当前设置 |
|---|---|
| 主设备 | OnePlus 6 |
| 设备代号 | `enchilada` |
| SoC | Qualcomm SDM845 |
| 架构 | ARM64 / AArch64 |
| 内核版本 | Linux 4.19.325 |
| Defconfig | `vendor/enchilada_defconfig` |
| 内核产物 | `Image.gz-dtb` |
| 附加产物 | `dtbo.img`、AnyKernel3 ZIP、构建来源与校验文件 |

源码中包含部分 OnePlus 6T（`fajita`）文件，但当前工作流只打包实际编译得到的 OnePlus 6 与通用 SDM845 DTBO。完成 OnePlus 6T 独立构建和真机验证前，本项目不声明完整支持 OnePlus 6T。

## 已集成功能

以下内容表示源码或配置中已经存在，不代表全部完成真机运行时验证。

### Root 与隐藏

- ReSukiSU v4.1.0
- SuSFS v2.1.00
- KernelPatch / SukiSU Ultra / KOWSU 兼容路径

### 网络

- BBR v1
- FQ_CODEL
- ipset
- Netfilter 扩展

> BBRv2 当前未启用。现有 4.19 TCP API 与已尝试的 BBRv2 实现不兼容，不能只打开配置项完成适配。

### 系统与兼容功能

- Baseband Guard（BBG）
- LZ4KD
- NTSYNC
- Docker 所需的部分 namespace、cgroup 与 overlayfs 支持
- Unicode 零宽字符绕过修复
- GPU 频率表与调度参数调整
- Adreno TZ GPU governor
- Step Wise Thermal governor

## 构建变体

以下说明以 2026-07-29 实际生成的 `kernel.config` 为准。

### Standard

- 默认 CPU governor：`Performance`
- CPU Boost：开启
- PM Autosleep：关闭
- Wakelock GC：关闭
- Workqueue 默认省电模式：关闭
- 面向响应速度和性能

### PowerSave

通过构建时配置补丁调整：

- 默认 CPU governor：`Schedutil`
- CPU Boost：关闭
- PM Autosleep：开启
- Wakelock GC：开启
- Workqueue 默认省电模式：开启
- 面向待机与功耗控制

Adreno TZ 与 Step Wise Thermal 在当前两种构建的最终配置中均已启用，不是 PowerSave 独占功能。

## 构建验证状态

2026-07-29 已对同一源码提交完成两种构建：

```text
kernel source SHA: bf3274c2e29d29b12c0ca7defc3269faac9d06ac
Standard run:       30429398821
PowerSave run:      30429398815
compiled DTBOs:     9
```

两种模式均完成：

- 内核与 DTBO 编译
- `Image.gz-dtb` 生成
- `dtbo.img` 重新打包
- AnyKernel3 ZIP 生成
- ZIP SHA256 校验
- 构建来源信息生成
- Artifact 上传

这只能标记为 **Build Verified**。尚未完成 OnePlus 6 实体机的 Boot Verified 与 Runtime Verified。

详细记录见：

```text
docs/BUILD_VERIFICATION_20260729.md
docs/VALIDATION_CHECKLIST.md
```

## 构建流程

### 入口工作流

```text
.github/workflows/build-standard.yml
.github/workflows/build-powersave.yml
```

### 共享工作流

```text
.github/workflows/build-kernel.yml
```

Standard 与 PowerSave 共用同一套编译、打包和校验逻辑，只通过输入参数选择构建模式，避免两份工作流长期漂移。

当前流程会：

1. 将 GitHub Token 权限限制为 `contents: read`。
2. 固定第三方 GitHub Actions 到提交 SHA。
3. 固定 AnyKernel3 与 `mkdtboimg.py` 到提交 SHA。
4. 解析并固定内核源码提交 SHA。
5. 使用源码提交时间作为内核构建时间。
6. 从源码重新编译 DTBO，不优先使用仓库内预编译 `dtbo.img`。
7. 生成 AnyKernel3 ZIP、SHA256、最终配置和来源信息。

## Artifact 内容

每个构建 Artifact 包含：

```text
ABK_OnePlus6_*.zip
ABK_OnePlus6_*.zip.sha256
BUILD_INFO.txt
BUILD_METADATA.sha256
DTBO_FILES.txt
kernel.config
```

`BUILD_INFO.txt` 记录：

- 内核源码仓库、分支和具体 SHA
- 构建仓库 SHA 与 Actions 运行链接
- Runner 镜像版本
- Clang、LLD 和交叉 GCC 版本
- AnyKernel3 与 DTBO 工具提交 SHA
- PowerSave 补丁 SHA256
- `Image.gz-dtb`、`dtbo.img` 和 `.config` SHA256

## AnyKernel3 安全设置

打包脚本启用了设备检查：

```text
do.devicecheck=1
device.name1=enchilada
device.name2=OnePlus6
```

工作流不再：

- 设置 `do.devicecheck=0`
- 下载未校验的 `vbmeta-disable-verification` 第三方二进制
- 使用每次随机生成的 testkey 对 ZIP 进行 `jarsigner` 签名

随机测试密钥不能建立可信发布身份，还会破坏产物可复现性。CI 产物是否兼容某个 Recovery，必须通过对应 Recovery 实测确认。

## 构建方法

1. 打开本仓库 **Actions** 页面。
2. 选择 `Build Standard` 或 `Build PowerSave`。
3. 点击 **Run workflow**。
4. 构建完成后下载 Artifact。
5. 使用 `.zip.sha256` 核对 ZIP。
6. 阅读 `BUILD_INFO.txt`，确认源码 SHA 和工具链。

## 刷入与回滚

推荐使用确认兼容 AnyKernel3 的自定义 Recovery 刷入完整 ZIP。

刷入前至少准备：

- 当前 ROM 对应的原版 `boot.img`
- 可用的 Fastboot 环境
- 可进入的 Recovery 或其他救砖路径
- 重要数据备份

### 禁止直接刷入裸内核

`Image.gz-dtb` 不是完整 Android `boot.img`。不要执行：

```text
fastboot flash boot Image.gz-dtb
```

直接写入会破坏原有 ramdisk 和启动镜像结构。

## 验证等级

| 层级 | 含义 | 当前状态 |
|---|---|---|
| Build Verified | CI 编译并生成完整 Artifact | Standard、PowerSave 已通过 |
| Boot Verified | 指定设备与 ROM 可以启动 | 待实体机测试 |
| Runtime Verified | 蜂窝、Wi-Fi、相机、指纹、充电、休眠、Root 等通过 | 待实体机测试 |
| Stable | 完成规定的稳定性观察并无阻断问题 | 未达到 |

## 上游状态

### 原始基线上游

```text
repository: shinichi-c/android_kernel_oneplus_sdm845
branch: lineage-23.0-4.19
baseline: 3019ce6cc4e9aab75da46761a3a9d03cee8937a3
```

源码仓库根提交基于该分支，并以功能已集成的源码快照形式导入。截至 2026-07-29，原始上游没有新增提交需要同步。

### 后续迁移参考

```text
repository: EdwinMoq/android_kernel_oneplus_sdm845
branch: lineage-23.2-4.19
observed: 91178f0c7899a2d9a3ccedfec9074c3648e4e78f
```

该分支与原始基线已经大幅分叉，属于完整迁移目标，不能直接覆盖或普通 merge 到当前源码树。迁移必须从干净新基线开始，逐项重新移植 ABK 功能。

## 发布命名

```text
ABK_OnePlus6_ReSukiSU_SuSFS210_<mode>_<source-sha>_<date>.zip
```

每个 Release 至少包含：

- 源码提交 SHA
- 构建工作流运行记录
- 工具链版本
- SHA256 校验值
- 设备、ROM 与固件版本
- 验证等级
- 已知问题
- 回滚方式

## 安全说明

- 本项目不修改基带固件，但内核改动仍可能影响蜂窝、休眠、充电和设备稳定性。
- 未完成 Boot Verified 的内核不应作为唯一日用启动环境。
- 不提交密钥、Token、账号信息、序列号或本机隐私路径。
- 安全关键依赖必须固定版本或提交并记录来源。

## 许可证与致谢

- Linux 内核源码：GPL-2.0
- AnyKernel3：遵循其上游许可证
- 其他补丁和工具：遵循各自上游许可证

感谢 OnePlusOSS、LineageOS、shinichi-c、EdwinMoq、ReSukiSU、SuSFS、AnyKernel3 及相关内核社区项目。
