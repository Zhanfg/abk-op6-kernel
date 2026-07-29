# ABK OnePlus 6 Kernel

面向 **OnePlus 6（enchilada / SDM845）** 的 Linux 4.19 自定义内核构建与发布仓库。

> 当前项目仍处于验证阶段。CI 能生成产物，不代表所有 ROM、Recovery 和硬件功能都已完成真机验证。刷入前必须准备可用的原版 `boot.img` 或其他可靠回滚方案。

## 项目组成

本项目由两个仓库共同组成：

| 仓库 | 作用 |
|---|---|
| [`Zhanfg/abk-op6-kernel`](https://github.com/Zhanfg/abk-op6-kernel) | GitHub Actions、Standard / PowerSave 构建、AnyKernel3 打包、发布文档 |
| [`Zhanfg/kernel_oneplus_sdm845`](https://github.com/Zhanfg/kernel_oneplus_sdm845) | OnePlus 6/6T SDM845 Linux 4.19 内核源码与已合入补丁 |

构建仓库默认从源码仓库的 `master` 分支拉取代码，因此源码更新后，后续构建会自动使用新的源码提交。

## 目标设备与基线

| 项目 | 当前设置 |
|---|---|
| 主设备 | OnePlus 6 |
| 设备代号 | `enchilada` |
| SoC | Qualcomm SDM845 |
| 架构 | ARM64 / AArch64 |
| 内核版本 | Linux 4.19.x |
| Defconfig | `vendor/enchilada_defconfig` |
| 内核产物 | `Image.gz-dtb` |
| 附加产物 | `dtbo.img`、AnyKernel3 ZIP |

源码中包含部分 OnePlus 6T（`fajita`）设备树覆盖文件，但当前构建仍以 `enchilada_defconfig` 为主。**未完成 OnePlus 6T 真机验证前，本项目不声明完整支持 OnePlus 6T。**

## 已集成功能

以下项目表示源码或配置中已经合入，不等同于全部通过真机运行时验证。

### Root 与隐藏

- ReSukiSU v4.1.0
- SuSFS v2.1.00
- KernelPatch / SukiSU Ultra / KOWSU 兼容路径

### 网络

- BBR v1
- FQ_CODEL
- ipset
- Netfilter 扩展

> BBRv2 当前未启用。现有 4.19 TCP API 与已尝试的 BBRv2 实现不兼容，不能仅通过打开配置项完成适配。

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
- 面向响应速度和日常性能

### PowerSave

在 Standard 基础上，通过构建时补丁调整：

- 关闭 CPU Boost
- 开启 PM Autosleep
- 开启 Workqueue 省电模式
- 开启 Wakelock GC
- 使用 Adreno TZ GPU governor
- 使用 Step Wise Thermal governor

PowerSave 是独立构建变体，不应把它的配置直接固化到源码仓库默认 defconfig 中。

## 当前验证状态

| 层级 | 含义 | 当前要求 |
|---|---|---|
| Build verified | CI 编译完成并生成完整 ZIP | 每次发布必须附 Actions 记录、源码 SHA 和校验值 |
| Boot verified | 指定设备与 ROM 可以正常开机 | 需要记录设备、ROM、固件和刷入方式 |
| Runtime verified | 蜂窝、Wi-Fi、相机、指纹、充电、休眠、Root 等通过测试 | 未完成前不得标记为 Stable |

仓库中的功能说明不能替代真机验收结果。发布页应明确标注属于 Experimental、Boot Verified 还是 Runtime Verified。

## 构建方法

1. 打开本仓库的 **Actions** 页面。
2. 选择 `Build Standard` 或 `Build PowerSave`。
3. 点击 **Run workflow**。
4. 构建完成后下载 Artifact。
5. 核对构建日志、源码提交和 ZIP 校验值。

两个工作流分别位于：

```text
.github/workflows/build-standard.yml
.github/workflows/build-powersave.yml
```

源码来源由工作流中的以下变量指定：

```yaml
KERNEL_SOURCE: https://github.com/Zhanfg/kernel_oneplus_sdm845
KERNEL_BRANCH: master
DEFCONFIG: vendor/enchilada_defconfig
```

## 刷入与回滚

### 推荐方式

使用兼容 AnyKernel3 的自定义 Recovery 刷入完整 ZIP。

刷入前至少准备：

- 当前系统对应的原版 `boot.img`
- 可用的 Fastboot 环境
- 可进入的 Recovery 或其他救砖路径
- 当前重要数据备份

### 不要这样操作

`Image.gz-dtb` 是内核镜像，不是完整的 Android `boot.img`。**不要直接执行下面的命令：**

```text
fastboot flash boot Image.gz-dtb
```

直接把裸内核镜像写入 `boot` 分区会破坏原有 ramdisk 和启动镜像结构，可能导致设备无法启动。

### Recovery 兼容性

构建流程会对 ZIP 进行 `jarsigner` 签名，但临时测试密钥签名本身不能证明该 ZIP 一定兼容 OxygenOS 官方 Recovery。官方 Recovery、TWRP、OrangeFox 或其他 Recovery 的兼容性必须分别实测并记录。

## 上游同步策略

当前 Linux 4.19 社区参考上游：

```text
EdwinMoq/android_kernel_oneplus_sdm845
branch: lineage-23.2-4.19
```

OnePlusOSS 与 LineageOS 的 OnePlus SDM845 官方/主流仓库主要基于 Linux 4.9。它们可以用于核对设备驱动和厂商修复，但不能直接覆盖当前 4.19 源码树。

上游同步遵循以下原则：

1. 只在源码仓库的独立同步分支中合并。
2. 不直接覆盖 ReSukiSU、SuSFS、BBG、网络栈和设备调优改动。
3. 先解决冲突，再完成 Standard 与 PowerSave 构建。
4. 至少完成 Boot Verified 后才合入发布分支。
5. 每次同步记录上游仓库、分支、提交 SHA 和冲突处理结果。

详细状态见 [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md)。

## 发布命名

建议统一使用：

```text
ABK-OnePlus6-enchilada-4.19-<variant>-<version>-<date>.zip
```

其中 `<variant>` 使用 `standard` 或 `powersave`。

每个 Release 至少应包含：

- 源码提交 SHA
- 构建工作流运行记录
- 工具链版本
- SHA256 校验值
- 设备与 ROM
- 验证层级
- 已知问题
- 回滚方式

## 安全说明

- 本项目不会修改基带固件，但内核改动仍可能影响蜂窝、休眠、充电和设备稳定性。
- 未经验证的内核不应作为唯一日用启动环境。
- 不要把密钥、Token、账号信息或本机隐私路径提交到仓库。
- 第三方脚本、Action 和二进制工具应固定版本并校验来源。

## 许可证与致谢

- Linux 内核源码：GPL-2.0
- AnyKernel3：遵循其上游许可证
- 其他补丁和工具：遵循各自上游许可证

感谢 OnePlusOSS、LineageOS、EdwinMoq、ReSukiSU、SuSFS、AnyKernel3 及相关内核社区项目。