# OnePlus 6 内核项目整理

更新时间：2026-07-29

## 1. 仓库关系

| 角色 | 仓库 | 默认分支 | 用途 |
|---|---|---|---|
| 主项目 | `Zhanfg/abk-op6-kernel` | `main` | GitHub Actions、构建变体、AnyKernel3 打包、项目文档 |
| 内核源码 | `Zhanfg/kernel_oneplus_sdm845` | `master` | 已预集成功能的 SDM845 / Linux 4.19 内核源码 |

这两个仓库应作为一个项目组维护，但不建议合并成单仓库：主项目负责可复现构建和发布，源码仓库负责内核代码与补丁历史。

## 2. 当前目标

- 主设备：OnePlus 6，代号 `enchilada`
- SoC：Qualcomm SDM845
- 内核：Linux 4.19
- 默认 defconfig：`vendor/enchilada_defconfig`
- 产物：`Image.gz-dtb`、`dtbo.img`、AnyKernel3 ZIP
- 构建变体：Standard、PowerSave

仓库同时收集了部分 OnePlus 6T（`fajita`）DTBO，但当前工作流仍以 `enchilada_defconfig` 为主。除非完成单独真机验证，不应把“包含 fajita DTBO”直接写成“完整支持 OnePlus 6T”。

## 3. 文件职责

| 路径 | 职责 |
|---|---|
| `.github/workflows/build-standard.yml` | 标准版构建与打包 |
| `.github/workflows/build-powersave.yml` | 省电版构建与打包 |
| `scripts/` | PowerSave 配置补丁和构建辅助内容 |
| `README.md` | 面向使用者的功能、刷写和编译说明 |
| `CHANGELOG.md` | 已发布版本的变更记录 |
| `docs/PROJECT_STATUS.md` | 仓库关系、验证状态和维护优先级 |

## 4. 当前状态

- README 与 CHANGELOG 已统一 BBR 为 v1，并明确 BBRv2 未启用。
- Standard 与 PowerSave 工作流均从独立源码仓库拉取代码。
- 工作流可生成内核、DTBO 和 AK3 ZIP。
- 构建成功不等于真机启动、休眠、蜂窝、相机、指纹和 Recovery 刷写均已验证。

建议后续每次发布都记录以下三种状态：

1. **Build verified**：CI 完成并生成完整产物。
2. **Boot verified**：指定设备和 ROM 可以正常开机。
3. **Runtime verified**：蜂窝、Wi-Fi、相机、指纹、充电、休眠和 Root 功能通过测试。

## 5. 已发现的维护风险

### 高优先级

- 工作流使用 `easimon/maximize-build-space@master`，未固定提交版本。
- `mkdtboimg.py`、AnyKernel3 和 vbmeta 工具在构建时直接联网下载，缺少固定提交或 SHA256 校验。
- 工作流权限包含 `contents: write` 和 `actions: write`，而普通 Artifact 构建通常只需要 `contents: read`。
- 生成的 `anykernel.sh` 设置 `do.devicecheck=0`，会降低误刷防护。
- 构建时临时生成 testkey 并进行 jarsigner 签名；该签名只能说明 ZIP 被某个临时密钥签过，不能自动证明兼容官方 Recovery。

### 中优先级

- Standard 与 PowerSave 工作流存在大量重复逻辑，后续容易出现只修一份的情况。
- 外部源码使用浅克隆，发布产物需要额外保存源码提交 SHA、工具链版本和依赖版本。
- README 中的性能提升幅度应只保留有测试方法和数据支持的结论。

## 6. 建议整理顺序

1. 固定所有第三方 Action、脚本和工具的版本或提交 SHA。
2. 将工作流权限缩减为最小权限。
3. 增加设备检查，并明确 OnePlus 6 与 OnePlus 6T 的验证边界。
4. 抽取 Standard / PowerSave 共用构建逻辑，减少重复。
5. 为 Artifact 写入源码 SHA、配置摘要、工具链版本和校验文件。
6. 建立真机验收表，在通过前不标记为稳定发布。

## 7. 发布命名建议

```text
ABK-OnePlus6-enchilada-4.19-<variant>-<version>-<date>.zip
```

其中 `<variant>` 仅使用 `standard` 或 `powersave`，并在 Release Notes 中附上源码提交、ROM、设备、测试结果和回退方式。
