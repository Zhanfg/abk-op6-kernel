# OnePlus 6 构建验证记录

验证日期：2026-07-29

验证范围：CI 构建、配置差异、AnyKernel3 包结构、来源信息与 SHA256。本文不代表实体机启动或运行时验证。

## 1. 公共基线

| 项目 | 值 |
|---|---|
| 构建仓库 | `Zhanfg/abk-op6-kernel` |
| 构建分支 | `ci/harden-reproducible-builds-20260729` |
| 内核源码 | `Zhanfg/kernel_oneplus_sdm845` |
| 内核源码 SHA | `bf3274c2e29d29b12c0ca7defc3269faac9d06ac` |
| Runner | `ubuntu-22.04` |
| Runner 镜像 | `20260720.234.2` |
| Clang | `14.0.0` |
| LLD | `14.0.0` |
| AArch64 GCC | `11.4.0` |
| AnyKernel3 SHA | `1c9a500dd4aa8081952523126e97eb155aed941b` |
| mkdtboimg SHA | `ca53bdb6c8ae5aaa890d4afebe66af55cfd906c8` |
| mkdtboimg 文件 SHA256 | `8542024196fba589ccccc6f6f6d728ffae3b149c146f9f289213945086a1a69e` |

## 2. Standard

| 项目 | 值 |
|---|---|
| Actions Run | `30429398821` |
| 结果 | Success |
| Artifact | `ABK_OnePlus6_ReSukiSU_SuSFS210_Standard_bf3274c2e29d_20260729-0716` |
| Artifact 大小 | 22,858,947 bytes |
| Artifact 外层摘要 | `sha256:37d4189aa08c1039c2b1590a738efe02d06594f94e4a31d4b6744043b5e699d5` |
| `Image.gz-dtb` SHA256 | `57ca322f77aad051bc6df746792ca992770630e86f0506240598f46d744c20b6` |
| `dtbo.img` SHA256 | `1b59c3fc66043811390c53e1401d61b4ce09e3e468457bab1fd95f4fa00bfd9e` |
| `.config` SHA256 | `506fc17b4bc685a92e789bf2e682d1696ea690d74412ae3a2e475410333083a3` |

最终配置要点：

```text
CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE=y
CONFIG_CPU_BOOST=y
# CONFIG_PM_AUTOSLEEP is not set
# CONFIG_PM_WAKELOCKS_GC is not set
# CONFIG_WQ_POWER_EFFICIENT_DEFAULT is not set
CONFIG_DEVFREQ_GOV_QCOM_ADRENO_TZ=y
CONFIG_THERMAL_GOV_STEP_WISE=y
```

## 3. PowerSave

| 项目 | 值 |
|---|---|
| Actions Run | `30429398815` |
| 结果 | Success |
| Artifact | `ABK_OnePlus6_ReSukiSU_SuSFS210_PowerSave_bf3274c2e29d_20260729-0718` |
| Artifact 大小 | 22,861,304 bytes |
| Artifact 外层摘要 | `sha256:1bb24e80cbb56285702c3f08eb33163e0718427ab35cfd64f0999ed70a2ffba5` |
| PowerSave 补丁 SHA256 | `b2b7128e30970a8fe7905bd6557fd7c92f9070d9302bf7da38afc7c627d0f1e7` |
| `Image.gz-dtb` SHA256 | `369942eafb91547efe2444066de3e914d8a06cdde10584b92ddbe9db8531ad1f` |
| `dtbo.img` SHA256 | `1b59c3fc66043811390c53e1401d61b4ce09e3e468457bab1fd95f4fa00bfd9e` |
| `.config` SHA256 | `0e0a7b388a6be89294cc7bbfbab91d4d405894c63e80fce1ab737f178cdff19a` |

最终配置要点：

```text
CONFIG_CPU_FREQ_DEFAULT_GOV_SCHEDUTIL=y
# CONFIG_CPU_BOOST is not set
CONFIG_PM_AUTOSLEEP=y
CONFIG_PM_WAKELOCKS_GC=y
CONFIG_WQ_POWER_EFFICIENT_DEFAULT=y
CONFIG_DEVFREQ_GOV_QCOM_ADRENO_TZ=y
CONFIG_THERMAL_GOV_STEP_WISE=y
```

## 4. DTBO

两种构建均重新编译并打包相同的 9 个 DTBO：

```text
enchilada-dvt-v2.1-backup-overlay.dtbo
enchilada-dvt-v2.1-overlay.dtbo
enchilada-dvt-v2.1-usb30-overlay.dtbo
enchilada-mp-v2.1-overlay.dtbo
enchilada-pvt-v2.1-backup-overlay.dtbo
enchilada-pvt-v2.1-overlay.dtbo
sdm845-mtp-overlay.dtbo
sdm845-v2-mtp-overlay.dtbo
sdm845-v2.1-mtp-overlay.dtbo
```

当前构建没有将未编译出的 `fajita` DTBO 填入产物，因此不能据此声明 OnePlus 6T 支持。

DTC 在编译通用 SDM845 DTB 时输出了既有的 `graph_port` unit-address 警告，但未阻断构建。后续迁移或设备树清理阶段需要单独核查，不能把“构建成功”视为警告已经解决。

## 5. AnyKernel3 包检查

两种 ZIP 均包含：

```text
Image.gz-dtb
dtbo.img
anykernel.sh
BUILD_INFO.txt
DTBO_FILES.txt
tools/ak3-core.sh
```

设备检查：

```text
do.devicecheck=1
device.name1=enchilada
device.name2=OnePlus6
```

同时确认：

- ZIP 对应 `.sha256` 校验通过。
- ZIP 内 `Image.gz-dtb` 与 `dtbo.img` 的实际 SHA256 和 `BUILD_INFO.txt` 记录一致。
- Standard 与 PowerSave 的 `dtbo.img` SHA256 相同。
- Standard 与 PowerSave 的内核和 `.config` SHA256 不同，说明变体配置实际生效。
- 未加入随机 testkey `jarsigner` 签名。
- 未加入未校验的 `vbmeta-disable-verification` 二进制。

## 6. 结论

| 验证层级 | Standard | PowerSave |
|---|---|---|
| Build Verified | 通过 | 通过 |
| Boot Verified | 未测试 | 未测试 |
| Runtime Verified | 未测试 | 未测试 |
| Stable | 未达到 | 未达到 |

下一步必须使用 OnePlus 6 实体机，按照 `docs/VALIDATION_CHECKLIST.md` 分别验证两种构建。不要仅凭本记录直接标记 Stable。
