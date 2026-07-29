# ABK OnePlus 6 Kernel

面向 **OnePlus 6（enchilada / SDM845）** 的 Linux 4.19 自定义内核构建与发布仓库。

> 当前项目仍处于验证阶段。CI 能生成产物，不代表所有 ROM、Recovery 和硬件功能都已完成真机验证。刷入前必须准备原版 `boot.img` 或其他可靠回滚方案。

## 项目组成

| 仓库 | 作用 |
|---|---|
| `Zhanfg/abk-op6-kernel` | GitHub Actions、Standard / PowerSave 构建、AnyKernel3 打包、发布文档 |
| `Zhanfg/kernel_oneplus_sdm845` | OnePlus 6 SDM845 Linux 4.19 源码、自定义功能与上游基线记录 |

本仓库默认从源码仓库 `master` 分支构建。

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
| 附加产物 | `dtbo.img`、AnyKernel3 ZIP |

源码中包含部分 OnePlus 6T（`fajita`）设备树和 DTBO，但当前构建仍以 `enchilada_defconfig` 为主。**完成 OnePlus 6T 单独真机验证前，本项目不声明完整支持 OnePlus 6T。**

## 已集成功能

以下项目表示源码或配置中已经合入，不等于全部完成真机运行时验证。

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

## 构建变体

### Standard

- 使用 `Schedutil` 调频器
- 保留 CPU Boost
- 面向日常响应和性能

### PowerSave

在 Standard 基础上，通过构建时补丁调整：

- 关闭 CPU Boost
- 开启 PM Autosleep
- 开启 Workqueue 省电模式
- 开启 Wakelock GC
- 使用 Adreno TZ GPU governor
- 使用 Step Wise Thermal governor

PowerSave 是独立构建变体，不应把其配置直接固化到源码仓库默认 defconfig。

## 验证等级

| 层级 | 含义 | 要求 |
|---|---|---|
| Build verified | CI 编译完成并生成完整 ZIP | 附 Actions 记录、源码 SHA 和校验值 |
| Boot verified | 指定设备与 ROM 可以正常开机 | 记录设备、ROM、固件和刷入方式 |
| Runtime verified | 蜂窝、Wi-Fi、相机、指纹、充电、休眠、Root 等通过测试 | 完成前不得标记 Stable |

仓库中的功能列表不能替代真机验收结果。

## 构建方法

1. 打开本仓库 **Actions** 页面。
2. 选择 `Build Standard` 或 `Build PowerSave`。
3. 点击 **Run workflow**。
4. 构建完成后下载 Artifact。
5. 核对源码提交、构建日志和 ZIP 校验值。

工作流位置：

```text
.github/workflows/build-standard.yml
.github/workflows/build-powersave.yml
```

源码设置：

```yaml
KERNEL_SOURCE: https://github.com/Zhanfg/kernel_oneplus_sdm845
KERNEL_BRANCH: master
DEFCONFIG: vendor/enchilada_defconfig
```

## 刷入与回滚

推荐使用兼容 AnyKernel3 的自定义 Recovery 刷入完整 ZIP。

刷入前至少准备：

- 当前系统对应的原版 `boot.img`
- 可用的 Fastboot 环境
- 可进入的 Recovery 或其他救砖路径
- 重要数据备份

### 禁止直接刷入裸内核

`Image.gz-dtb` 是内核镜像，不是完整 Android `boot.img`。**不要执行：**

```text
fastboot flash boot Image.gz-dtb
```

直接将裸内核写入 `boot` 分区会破坏原有 ramdisk 和启动镜像结构。

### Recovery 兼容性

构建流程会对 ZIP 进行 `jarsigner` 签名，但临时测试密钥签名不能证明该 ZIP兼容 OxygenOS 官方 Recovery。官方 Recovery、TWRP、OrangeFox 等环境必须分别实测。

## 上游状态

### 原始基线上游

```text
repository: shinichi-c/android_kernel_oneplus_sdm845
branch: lineage-23.0-4.19
baseline: 3019ce6cc4e9aab75da46761a3a9d03cee8937a3
```

源码仓库根提交明确基于该分支，并已一次性集成完整 ABK 功能。截至 2026-07-29，原始上游 HEAD 仍为上述提交，**当前没有新增提交需要同步**。

由于本地源码以“功能已集成的快照”导入，没有保留原始上游 Git 历史，不能使用 GitHub `Sync fork` 或普通 merge 来恢复关系。

### 后续迁移参考

```text
repository: EdwinMoq/android_kernel_oneplus_sdm845
branch: lineage-23.2-4.19
observed: 91178f0c7899a2d9a3ccedfec9074c3648e4e78f
```

该分支与原始 `lineage-23.0-4.19` 已大幅分叉，属于完整版本迁移目标，不是可以直接同步的普通上游。迁移时必须从干净新基线开始，逐项重新移植 ABK 功能并完成构建与真机验证。

OnePlusOSS 与 LineageOS 的主流 SDM845 仓库仍以 Linux 4.9 为主，只用于厂商驱动和设备修复参考。

详细核查记录位于源码仓库：

```text
UPSTREAM.md
UPSTREAM_BASELINE.env
```

## 发布命名

```text
ABK-OnePlus6-enchilada-4.19-<variant>-<version>-<date>.zip
```

`<variant>` 使用 `standard` 或 `powersave`。

每个 Release 至少应包含：

- 源码提交 SHA
- 构建工作流运行记录
- 工具链版本
- SHA256 校验值
- 设备与 ROM
- 验证等级
- 已知问题
- 回滚方式

## 安全说明

- 本项目不修改基带固件，但内核改动仍可能影响蜂窝、休眠、充电和设备稳定性。
- 未经验证的内核不应作为唯一日用启动环境。
- 不要提交密钥、Token、账号信息或本机隐私路径。
- 第三方脚本、Action 和二进制工具应固定版本并校验来源。

## 许可证与致谢

- Linux 内核源码：GPL-2.0
- AnyKernel3：遵循其上游许可证
- 其他补丁和工具：遵循各自上游许可证

感谢 OnePlusOSS、LineageOS、shinichi-c、EdwinMoq、ReSukiSU、SuSFS、AnyKernel3 及相关内核社区项目。