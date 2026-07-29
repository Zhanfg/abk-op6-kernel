# OnePlus 6 内核项目状态

更新时间：2026-07-29

## 1. 仓库关系

| 角色 | 仓库 | 默认分支 | 用途 |
|---|---|---|---|
| 构建与发布 | `Zhanfg/abk-op6-kernel` | `main` | GitHub Actions、构建变体、AnyKernel3 打包、发布文档 |
| 内核源码 | `Zhanfg/kernel_oneplus_sdm845` | `master` | SDM845 / Linux 4.19 源码、自定义功能和上游基线记录 |

两个仓库作为同一个 OnePlus 6 项目维护。构建仓库负责可重复构建与发布，源码仓库负责代码、配置、上游核查和后续迁移。

## 2. 当前目标

- 主设备：OnePlus 6，代号 `enchilada`
- SoC：Qualcomm SDM845
- 内核：Linux 4.19.325
- 默认 defconfig：`vendor/enchilada_defconfig`
- 产物：`Image.gz-dtb`、`dtbo.img`、AnyKernel3 ZIP
- 构建变体：Standard、PowerSave

完成 OnePlus 6T 独立构建和真机验证前，不声明完整支持 `fajita`。

## 3. 上游状态

### 原始基线上游

```text
shinichi-c/android_kernel_oneplus_sdm845
branch: lineage-23.0-4.19
baseline: 3019ce6cc4e9aab75da46761a3a9d03cee8937a3
```

源码仓库以功能已集成的快照形式导入，没有保留原始上游 Git 祖先关系。截至 2026-07-29，原始上游 HEAD 没有变化，因此当前没有普通上游提交需要同步。

### 迁移参考

```text
EdwinMoq/android_kernel_oneplus_sdm845
branch: lineage-23.2-4.19
observed: 91178f0c7899a2d9a3ccedfec9074c3648e4e78f
```

该分支与原始基线大幅分叉，只能作为完整迁移目标。禁止整树覆盖或自动 merge 到当前 `master`。

## 4. 已完成的上游诊断

- 确认本地与 EdwinMoq 分支没有共同 Git 祖先。
- 确认两者内核版本均为 4.19.325。
- 确认整树差异重放会混入大量非项目变化和功能冲突。
- 在迁移参考历史中未找到与本地根 tree hash 完全相同的提交。
- 根据本地根提交说明定位到真实原始上游。
- 源码仓库已改为只读检查原始上游 HEAD，不再自动修改源码。

## 5. 构建流程状态

### 已完成

- Standard 与 PowerSave 已改为调用同一共享工作流。
- GitHub Token 权限缩减为 `contents: read`。
- GitHub Actions 固定到明确提交 SHA。
- AnyKernel3 与 `mkdtboimg.py` 固定到明确提交 SHA。
- 每次构建固定内核源码提交 SHA。
- 使用源码提交时间作为内核构建时间。
- `dtbo.img` 从本次编译生成的 DTBO 重新打包。
- AnyKernel3 启用设备检查。
- 删除随机 testkey `jarsigner` 签名。
- 删除未校验 `vbmeta-disable-verification` 下载。
- Artifact 增加源码、工具链、配置、DTBO 清单和 SHA256 信息。
- 建立实体机验收表。

### 工作流文件

| 路径 | 职责 |
|---|---|
| `.github/workflows/build-standard.yml` | Standard 入口 |
| `.github/workflows/build-powersave.yml` | PowerSave 入口 |
| `.github/workflows/build-kernel.yml` | 共享编译、打包和校验逻辑 |
| `scripts/powersave_defconfig.patch` | PowerSave 配置差异 |

## 6. 构建验证

公共内核源码提交：

```text
bf3274c2e29d29b12c0ca7defc3269faac9d06ac
```

| 模式 | Actions Run | 结果 | DTBO 数量 |
|---|---:|---|---:|
| Standard | `30429398821` | Success | 9 |
| PowerSave | `30429398815` | Success | 9 |

两种 Artifact 均完成：

- ZIP SHA256 验证
- AnyKernel3 必需文件检查
- 内层 `Image.gz-dtb` 和 `dtbo.img` 哈希核对
- 构建来源信息核对
- 最终 `.config` 差异核对

详细记录：

```text
docs/BUILD_VERIFICATION_20260729.md
docs/VALIDATION_CHECKLIST.md
```

## 7. 实际构建变体

### Standard

```text
CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE=y
CONFIG_CPU_BOOST=y
# CONFIG_PM_AUTOSLEEP is not set
# CONFIG_PM_WAKELOCKS_GC is not set
# CONFIG_WQ_POWER_EFFICIENT_DEFAULT is not set
```

### PowerSave

```text
CONFIG_CPU_FREQ_DEFAULT_GOV_SCHEDUTIL=y
# CONFIG_CPU_BOOST is not set
CONFIG_PM_AUTOSLEEP=y
CONFIG_PM_WAKELOCKS_GC=y
CONFIG_WQ_POWER_EFFICIENT_DEFAULT=y
```

`CONFIG_DEVFREQ_GOV_QCOM_ADRENO_TZ` 和 `CONFIG_THERMAL_GOV_STEP_WISE` 在两种最终配置中均为启用状态，不是 PowerSave 独占差异。

## 8. 验证等级

| 等级 | 当前状态 |
|---|---|
| Build Verified | Standard、PowerSave 已通过 |
| Boot Verified | 待 OnePlus 6 实体机测试 |
| Runtime Verified | 待实体机完整功能测试 |
| Stable | 未达到 |

构建成功不能证明蜂窝、相机、指纹、充电、休眠、Recovery、Root 和 SuSFS 已在实体机通过。

## 9. 剩余风险

### 高优先级

- 根提交一次性集成大量 ABK 功能，原始补丁边界不清晰。
- 尚未在 OnePlus 6 实体机验证两种构建。
- DTS 编译存在既有 `graph_port` unit-address 警告，需要在迁移或设备树清理阶段核查。
- Recovery 兼容性尚未分别验证。

### 中优先级

- APT 安装的编译器包会随 Ubuntu 软件仓库更新；当前流程会记录版本，但尚未使用完整容器镜像固定系统工具链。
- 尚未建立可逐项重放的 ABK 补丁目录。
- 尚未开始 `lineage-23.2-4.19` 迁移分支。
- Standard 使用 Performance 作为默认 governor，需要结合实体机功耗和温控结果决定是否调整。

## 10. 下一阶段顺序

1. 使用 `docs/VALIDATION_CHECKLIST.md` 完成 Standard 实体机测试。
2. 回滚原版 `boot.img`，再测试 PowerSave。
3. 保存启动、蜂窝、相机、指纹、充电、休眠和 Root 结果。
4. 收集异常时的 `dmesg`、pstore 或对应崩溃日志。
5. 根据实体机结果决定 Standard 默认 governor 是否需要改为 Schedutil。
6. 将根提交中的 ABK 功能拆分成可追踪补丁组。
7. 新建 `migration/lineage-23.2-4.19` 分支，从干净新基线逐项移植。

## 11. 发布要求

发布文件名：

```text
ABK_OnePlus6_ReSukiSU_SuSFS210_<mode>_<source-sha>_<date>.zip
```

Release Notes 必须附：

- 内核源码 SHA
- Actions Run
- ZIP SHA256
- 工具链版本
- 设备、ROM 和固件版本
- 验证等级
- 已知问题
- 回滚方式
