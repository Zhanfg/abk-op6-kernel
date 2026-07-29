# OnePlus 6 内核项目状态

更新时间：2026-07-29

## 1. 仓库关系

| 角色 | 仓库 | 默认分支 | 用途 |
|---|---|---|---|
| 主项目 | `Zhanfg/abk-op6-kernel` | `main` | GitHub Actions、构建变体、AnyKernel3 打包、发布文档 |
| 内核源码 | `Zhanfg/kernel_oneplus_sdm845` | `master` | 已预集成功能的 SDM845 / Linux 4.19 内核源码与上游基线记录 |

两个仓库作为一个 OnePlus 6 项目组维护：主项目负责构建和发布，源码仓库负责内核代码与迁移工作。

## 2. 当前目标

- 主设备：OnePlus 6，代号 `enchilada`
- SoC：Qualcomm SDM845
- 内核：Linux 4.19.325
- 默认 defconfig：`vendor/enchilada_defconfig`
- 产物：`Image.gz-dtb`、`dtbo.img`、AnyKernel3 ZIP
- 构建变体：Standard、PowerSave

源码同时包含部分 OnePlus 6T（`fajita`）设备树与 DTBO，但当前工作流仍以 `enchilada_defconfig` 为主。未完成单独真机验证前，不声明完整支持 OnePlus 6T。

## 3. 已确认的上游关系

### 原始基线上游

```text
shinichi-c/android_kernel_oneplus_sdm845
branch: lineage-23.0-4.19
baseline: 3019ce6cc4e9aab75da46761a3a9d03cee8937a3
```

源码仓库根提交明确说明基于该分支，并已在根提交中一次性集成完整 ABK 功能。截至 2026-07-29，原始上游 HEAD 仍为记录的基线 SHA，因此当前没有新增原始上游提交需要同步。

本地仓库是功能集成后的源码快照，没有保留原始上游 Git 祖先关系，不能使用普通 `git merge` 或 GitHub `Sync fork` 恢复历史。

### 后续迁移参考

```text
EdwinMoq/android_kernel_oneplus_sdm845
branch: lineage-23.2-4.19
observed: 91178f0c7899a2d9a3ccedfec9074c3648e4e78f
```

该分支与原始基线大幅分叉，属于完整版本迁移目标，不是普通上游更新。禁止整树覆盖或自动 merge；需要从干净新基线重新移植 ABK 功能。

### 其他参考

- `OnePlusOSS/android_kernel_oneplus_sdm845`
- `LineageOS/android_kernel_oneplus_sdm845`

这些仓库的主流基线仍是 Linux 4.9，仅用于追踪厂商驱动和设备修复。

## 4. 已完成的上游诊断

- 确认本地与 EdwinMoq 分支没有共同 Git 祖先。
- 确认两者内核版本均为 4.19.325。
- 尝试整树差异重放，发现会混入新增组件、缺失文件、文件模式变化、defconfig、SuSFS 和 Netfilter 冲突。
- 在 EdwinMoq 完整历史中未找到与本地根 tree hash 完全一致的提交。
- 根据本地根提交说明，定位到真正原始上游 `shinichi-c:lineage-23.0-4.19`。
- 将源码仓库自动流程改为只读上游 HEAD 检查，不再尝试自动合并源码。

## 5. 文件职责

| 路径 | 职责 |
|---|---|
| `.github/workflows/build-standard.yml` | 标准版构建与打包 |
| `.github/workflows/build-powersave.yml` | 省电版构建与打包 |
| `scripts/` | PowerSave 配置补丁和构建辅助内容 |
| `README.md` | 面向使用者的功能、刷写、回滚和编译说明 |
| `CHANGELOG.md` | 已发布版本的变更记录 |
| `docs/PROJECT_STATUS.md` | 仓库关系、上游、验证状态和维护优先级 |

源码仓库额外包含：

| 路径 | 职责 |
|---|---|
| `README.md` | 源码定位与当前上游关系 |
| `UPSTREAM.md` | 上游诊断和迁移规范 |
| `UPSTREAM_BASELINE.env` | 固定原始上游、迁移参考和本地根提交 SHA |
| `.github/workflows/sync-upstream.yml` | 只读检查原始上游 HEAD 是否变化 |

## 6. 当前状态

- README 与 CHANGELOG 已统一 BBR 为 v1，并明确 BBRv2 未启用。
- Standard 与 PowerSave 工作流均从独立源码仓库拉取代码。
- 工作流具备生成内核、DTBO 和 AK3 ZIP 的配置。
- README 已移除直接把 `Image.gz-dtb` 写入 `boot` 分区的错误指引。
- 原始上游当前没有新增提交。
- 迁移到 `lineage-23.2-4.19` 尚未开始，不得宣称已完成上游升级。
- 构建成功不等于真机启动、休眠、蜂窝、相机、指纹和 Recovery 刷写均已验证。

验证等级：

1. **Build verified**：CI 完成并生成完整产物。
2. **Boot verified**：指定设备和 ROM 可以正常开机。
3. **Runtime verified**：蜂窝、Wi-Fi、相机、指纹、充电、休眠和 Root 功能通过测试。

## 7. 已发现的维护风险

### 高优先级

- 工作流使用 `easimon/maximize-build-space@master`，未固定提交版本。
- `mkdtboimg.py`、AnyKernel3 和 vbmeta 工具在构建时直接联网下载，缺少固定提交或 SHA256 校验。
- 构建工作流权限包含 `contents: write` 和 `actions: write`，普通 Artifact 构建通常不需要这些写权限。
- 生成的 `anykernel.sh` 设置 `do.devicecheck=0`，误刷防护不足。
- 构建时临时生成 testkey 并进行 jarsigner 签名；该签名不能证明兼容官方 Recovery。
- 根提交包含大量功能，原始 ABK 补丁边界不清晰，后续迁移难度较高。

### 中优先级

- Standard 与 PowerSave 工作流存在大量重复逻辑，容易只修一份。
- 外部源码使用浅克隆，发布产物需要保存源码 SHA、工具链和依赖版本。
- README 中的性能结论必须有测试方法和数据支持。
- 尚未建立可逐项重放的 ABK 补丁目录。

## 8. 后续执行顺序

1. 固定第三方 Action、脚本和工具的版本或提交 SHA。
2. 缩减构建工作流权限。
3. 增加设备检查和产物元数据。
4. 运行 Standard 与 PowerSave 构建，确认当前 `master` 仍可复现。
5. 建立真机验收表。
6. 将根提交中的 ABK 功能拆分为可追踪补丁组。
7. 新建 `migration/lineage-23.2-4.19` 分支，从干净上游逐项移植。
8. 每个迁移阶段分别完成构建和真机验证。

## 9. 发布命名

```text
ABK-OnePlus6-enchilada-4.19-<variant>-<version>-<date>.zip
```

`<variant>` 使用 `standard` 或 `powersave`。Release Notes 必须附源码 SHA、上游基线、ROM、设备、测试结果、已知问题和回退方式。