# OnePlus 6 内核验收表

更新时间：2026-07-29

本表用于区分 **Build Verified**、**Boot Verified** 和 **Runtime Verified**。只有完成对应项目后，发布说明才可以使用相应标记。

## 1. 构建记录

| 项目 | Standard | PowerSave |
|---|---|---|
| GitHub Actions 运行链接 |  |  |
| 构建仓库 SHA |  |  |
| 内核源码 SHA |  |  |
| ZIP 文件名 |  |  |
| ZIP SHA256 |  |  |
| `Image.gz-dtb` SHA256 |  |  |
| `dtbo.img` SHA256 |  |  |
| `.config` SHA256 |  |  |
| DTBO 数量 |  |  |
| 编译结果 | ☐ | ☐ |
| Artifact 内容完整 | ☐ | ☐ |

构建产物必须包含：

- AnyKernel3 ZIP
- ZIP 对应的 `.sha256`
- `BUILD_INFO.txt`
- `BUILD_METADATA.sha256`
- `DTBO_FILES.txt`
- `kernel.config`

## 2. 刷入前信息

| 项目 | 记录 |
|---|---|
| 设备 | OnePlus 6 (`enchilada`) |
| 设备型号 |  |
| ROM 名称与版本 |  |
| Android 版本 |  |
| 固件/基带版本 |  |
| Recovery |  |
| Root 管理器版本 |  |
| 刷入前内核 |  |
| 测试变体 | Standard / PowerSave |
| 原版 `boot.img` 已备份 | ☐ |
| Fastboot 可用 | ☐ |
| Recovery 可进入 | ☐ |
| 重要数据已备份 | ☐ |

## 3. Boot Verified

- [ ] AnyKernel3 正确识别 `enchilada` 或 `OnePlus6`
- [ ] 非 OnePlus 6 设备会被设备检查阻止
- [ ] ZIP 正常完成 boot 镜像解包、重打包和写入
- [ ] 设备可以进入系统
- [ ] 没有 bootloop、自动重启或卡第一屏
- [ ] `uname -a` 与构建信息符合预期
- [ ] 可以正常进入 Recovery
- [ ] 原版 `boot.img` 回滚成功

## 4. Runtime Verified

### 基础硬件

- [ ] SIM 卡识别
- [ ] 通话正常
- [ ] 移动数据正常
- [ ] Wi-Fi 正常
- [ ] 蓝牙正常
- [ ] GPS 正常
- [ ] 相机前后摄正常
- [ ] 指纹正常
- [ ] 屏幕亮度与自动亮度正常
- [ ] 振动、扬声器和麦克风正常
- [ ] USB 数据连接正常

### 电源与温控

- [ ] 有线充电正常
- [ ] 电池电量和温度显示正常
- [ ] 灭屏后可以进入休眠
- [ ] 无异常高频唤醒
- [ ] 无明显待机掉电异常
- [ ] 高负载下温控工作正常
- [ ] Standard 的 CPU Boost 行为符合预期
- [ ] PowerSave 的 CPU Boost 已关闭
- [ ] PowerSave 的 Autosleep、Wakelock GC 和省电 Workqueue 已生效

### Root 与隐藏

- [ ] ReSukiSU 管理器可以识别内核
- [ ] Root 授权正常
- [ ] SuSFS 基础功能正常
- [ ] 应用隐藏和挂载命名空间功能正常
- [ ] 没有因 Root/SuSFS 导致的随机崩溃或卡死

### 网络与附加功能

- [ ] BBR v1 可用
- [ ] FQ_CODEL 可用
- [ ] ipset 和所需 Netfilter 扩展可用
- [ ] BBRv2 未被误启用
- [ ] NTSYNC 接口存在
- [ ] Docker/LXC 所需配置与实际使用场景通过测试
- [ ] Baseband Guard 没有破坏正常蜂窝功能

## 5. 稳定性观察

建议至少完成：

- [ ] 连续启动 5 次无失败
- [ ] 待机 8 小时无异常重启
- [ ] 日常使用 24 小时无内核崩溃
- [ ] 相机、通话、充电和休眠均重复测试
- [ ] 检查 `dmesg`、`pstore`、`last_kmsg` 或对应崩溃日志

## 6. 发布结论

| 结论 | 状态 |
|---|---|
| Build Verified | ☐ |
| Boot Verified | ☐ |
| Runtime Verified | ☐ |
| Stable | ☐ |

已知问题：

```text
在此记录问题、复现步骤和临时规避方法。
```

测试人：

```text
仅填写网名或 GitHub 用户名，不填写真实隐私信息。
```
