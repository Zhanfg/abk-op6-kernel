# OnePlus 6 内核项目状态

更新时间：2026-07-29

## 1. 仓库关系

| 角色 | 仓库 | 默认分支 | 用途 |
|---|---|---|---|
| 主项目 | `Zhanfg/abk-op6-kernel` | `main` | GitHub Actions、构建变体、AnyKernel3 打包、发布文档 |
| 内核源码 | `Zhanfg/kernel_oneplus_sdm845` | `master` | 已预集成功能的 SDM845 / Linux 4.19 内核源码 |

两个仓库作为一个项目组维护：主项目负责可复现构建和发布，源码仓库负责内核代码、补丁历史和上游同步。

## 2. 当前目标

- 主设备：OnePlus 6，代号 `enchilada`
- SoC：Qualcomm SDM845
- 内核：Linux 4.19
- 默认 defconfig：`vendor/enchilada_defconfig`
- 产物：`Image.gz-dtb`、`dtbo.img`、AnyKernel3 ZIP
- 构建变体：Standard、PowerSave

仓库同时包含部分 OnePlus 6T（`fajita`）DTBO，但当前工作流仍以 `enchilada_defconfig` 为主。未完成单独真机验证前，不声明完整支持 OnePlus 6T。

## 3. 上游关系

### 当前 4.19 社区上游

```text
EdwinMoq/android_kernel_oneplus_sdm845
branch: lineage-23.2-4.19
```

该分支与当前源码树使用相同的 Linux 4.19.325 基线，可作为设备、安全、相机、电池及编译兼容性更新的主要参考。

### 官方与主流参考

- `OnePlusOSS/android_kernel_oneplus_sdm845`
- `LineageOS/android_kernel_oneplus_sdm845`

这两个仓库的主流基线仍是 Linux 4.9。它们可用于追踪厂商驱动和设备修复，但不能直接覆盖当前 4.19 树。

### 同步规则

1. 仅在独立 `sync/upstream-*` 分支中尝试合并。
2. 不直接覆盖 ReSukiSU、SuSFS、BBG、网络栈和设备调优改动。
3. 保存上游仓库、分支和提交 SHA。
4. 合并后必须完成 Standard 与 PowerSave 构建。
5. 至少完成 Boot Verified 后再进入发布分支。
6. 存在冲突时保留冲突清单，不使用 `ours` 策略伪造同步完成。

## 4. 文件职责

| 路径 | 职责 |
|---|---|
| `.github/workflows/build-standard.yml` | 标准版构建与打包 |
| `.github/workflows/build-powersave.yml` | 省电版构建与打包 |
| `scripts/` | PowerSave 配置补丁和构建辅助内容 |
| `README.md` | 面向使用者的功能、刷写、回滚和编译说明 |
| `CHANGELOG.md` | 已发布版本的变更记录 |
| `docs/PROJECT_STATUS.md` | 仓库关系、上游、验证状态和维护优先级 |

## 5. 当前状态

- README 与 CHANGELOG 已统一 BBR 为 v1，并明确 BBRv2 未启用。
- Standard 与 PowerSave 工作流均从独立源码仓库拉取代码。
- 工作流具备生成内核、DTBO 和 AK3 ZIP 的配置。
- README 已移除直接把 `Image.gz-dtb` 写入 `boot` 分区的错误指引。
- 构建成功不等于真机启动、休眠、蜂窝、相机、指纹和 Recovery 刷写均已验证。

建议后续每次发布记录以下状态：

1. **Build verified**：CI 完成并生成完整产物。
2. **Boot verified**：指定设备和 ROM 可以正常开机。
3. **Runtime verified**：蜂窝、Wi-Fi、相机、指纹、充电、休眠和 Root 功能通过测试。

## 6. 已发现的维护风险

### 高优先级

- 工作流使用 `easimon/maximize-build-space@master`，未固定提交版本。
- `mkdtboimg.py`、AnyKernel3 和 vbmeta 工具在构建时直接联网下载，缺少固定提交或 SHA256 校验。
- 工作流权限包含 `contents: write` 和 `actions: write`，普通 Artifact 构建通常不需要这些写权限。
- 生成的 `anykernel.sh` 设置 `do.devicecheck=0`，误刷防护不足。
- 构建时临时生成 testkey 并进行 jarsigner 签名；该签名不能自动证明兼容官方 Recovery。
- 源码仓库与 4.19 上游不属于同一 GitHub Fork 网络，不能依赖 GitHub 原生跨仓库更新按钮。

### 中优先级

- Standard 与 PowerSave 工作流存在大量重复逻辑，后续容易只修一份。
- 外部源码使用浅克隆，发布产物需要保存源码提交 SHA、工具链版本和依赖版本。
- README 中的性能提升幅度应只保留有测试方法和数据支持的结论。
- 当前还没有统一的上游冲突报告和构建验证流程。

## 7. 建议执行顺序

1. 在源码仓库建立安全的上游同步工作流。
2. 获取上游差异并生成独立同步 PR，不自动合并。
3. 解决冲突并执行 Standard / PowerSave 构建。
4. 固定第三方 Action、脚本和工具的版本或提交 SHA。
5. 将构建工作流权限缩减为最小权限。
6. 增加设备检查，并明确 OnePlus 6 与 OnePlus 6T 的验证边界。
7. 为 Artifact 写入源码 SHA、配置摘要、工具链版本和校验文件。
8. 建立真机验收表，在通过前不标记为稳定发布。

## 8. 发布命名

```text
ABK-OnePlus6-enchilada-4.19-<variant>-<version>-<date>.zip
```

其中 `<variant>` 仅使用 `standard` 或 `powersave`。Release Notes 必须附上源码提交、上游提交、ROM、设备、测试结果、已知问题和回退方式。