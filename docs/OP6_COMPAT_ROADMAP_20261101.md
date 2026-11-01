# OnePlus 6 (enchilada) — 第二轮兼容性预研与实施门槛

日期：2026-11-01。基于已通过 CI 的 BakaSU Standard 基线构建提交
`36c57f94ff66e72a70755a8c0c8159d55db77c31`，内核源固定
`ZhanfgBuild/kernel_oneplus_sdm845@cad392026e27ac91bd88d225320868bd2dfaa667`，
BakaSU 固定 `Baka-SU/BakaSU@516d3e87fbc986ccefdde2c2765f1700612441a9`。

**绝不直接修改已成功构建的基线。此分支仅用于兼容性准备与后续实验。**

## 固定边界

- Linux 4.19.325 / ARM64 / OnePlus 6；`CONFIG_KSU=y`、`CONFIG_KSU_MANUAL_HOOK=y` 为稳定回退。
- 不启用 SuSFS，不加入 SuSFS Inline Hook；不引入 PowerSave 补丁。
- 不同时编译四个 Root 引擎。**一个 BakaSU 内核后端、多套独立 APK 管理器并存**。
- 不通过关闭签名校验、放开任意包名、任意 UID、伪造管理器证书来实现兼容。
- 实验组件均设独立编译/运行时门槛，CI 通过不等于真机可用。

## 1. 四管理器目标

| 管理器 | 当前 BakaSU 原生证书白名单 | 第二轮目标 | 当前可声明 |
| --- | --- | --- | --- |
| 官方 KernelSU (`tiann/KernelSU`) | 已包含 | 认证+协议+Root/策略+管理器切换回归 | 仅构建支持；实际 APK 未测 |
| KernelSU Next (`KernelSU-Next/KernelSU-Next`) | 不包含 | 增加明确证书白名单，兼容 supercall、模块配置/API | 未实现 |
| SukiSU Ultra (`SukiSU-Ultra/SukiSU-Ultra`) | 不包含 | 增加明确证书白名单，兼容特性探测/KPM/挂载差异 | 未实现 |
| BakaSU (`Baka-SU/BakaSU`) | 已包含 | 作为原生控制面，稳定回退；管理器换入/换出 | 仅构建支持；实际 APK 未测 |

现有 BakaSU 内核的 `kernel/manager/apk_sign.c` 白名单为：
BakaSU、官方 KernelSU、KOWX712（后两项在 `CONFIG_KSU_MULTI_MANAGER_SUPPORT` 下）。
**目标 EXP 白名单限定四个用户指定分支**（官方 KernelSU、Next、SukiSU Ultra、BakaSU）；
上游默认包含的 KOWX712 在 EXP 版本中作为可移除的历史兼容项，不计入四管理器验收，
不额外扩大信任范围；在基线 Standard 上不贸然删除上游默认项。
`kernel/manager/manager.c` 使用可包含多个 `appid` 的 RCU 链表，
`manager/throne_tracker.c` 负责发现/注册管理器；
`feature/dynamic_manager.c` 只有**一个**可动态改写的证书槽位，
不能视作 Next 与 SukiSU **同时**被长期认证的解决方案。

上游默认构建签名参数（**仅作为开发期来源，非已验证 APK 认证结果**）：
- 官方 KernelSU: `kernel/Kbuild` 的 `0x033b` 与 `c371061b19d8c7d7d6133c6a9bafe198fa944e50c1b31c9d8daa8d7f1fc2d2d6`；
- KernelSU Next: `kernel/Kbuild` 的 `0x3e6` 与 `79e590113c4c4c0c222978e413a5faa801666957b1212a328e46c00c69821bf7`；
- SukiSU Ultra: `kernel/Kbuild` 的 `0x35c` 与 `947ae944f3de4ed4c21a7e4f7953ecf351bfa2b36239da37a34111ad29993eef`；
- BakaSU: `kernel/manager/manager_sign.h` 的 `0x377` 与 `d3469712b6214462764a1d8d3e5cbe1d6819a0b629791b9f4101867821f1df64`。

**不能仅复制这些参数就宣称兼容**。下一轮先下载各官方 Release APK，
验证 APK v2/v3 证书链和实际签名与期望一致，再为固定来源建立白名单。
检测用户安装/卸载、同包覆盖、多用户、多个管理器并存/切换；
预先规定当不同 Manager 的命令协议和模块格式不匹配时明确拒绝写操作，不做危险的无声回退。

### 优先修复的 BakaSU 上游问题候选

`kernel/manager/manager.c::ksu_unregister_manager()` 中，
在撤销当前 `ksu_last_manager_appid` 时，代码可能把它重新赋值为
正在移除的 `appid`，而不是剩余 manager 的 `appid`。
必须先以测试复现，再修复“卸载主管理器以后次管理器仍可授权”的情形。
还要核查卸载和注册与 RCU 遍历的竞争、`appid` 在多用户 UID 下的处理。

## 2. Tracepoint Hook 回移（**实验后端，不改变稳定后端**）

**已知证据**：
- BakaSU Kconfig / Kbuild 对 `CONFIG_KSU_TRACEPOINT_HOOK` 的现行约束是 GKI2、Linux 5.10+；
  4.19 的正确默认仍是 `CONFIG_KSU_MANUAL_HOOK=y`。
- 目标内核 `include/trace/events/syscalls.h` 含 `sys_enter`，
  `kernel/trace/trace_syscalls.c` 含 `register_trace_sys_enter`，
  ARM64 `TIF_SYSCALL_TRACEPOINT` 存在。
  **仅说明具有基础设施，不证明重定向机制在 4.19 可工作**。
- BakaSU 当前 `kernel/hook/syscall_hook_manager.c` 依赖
  `register_trace_prio_sys_enter`、`CONFIG_HAVE_SYSCALL_TRACEPOINTS`、
  `hook/arm64/syscall_hook.c` 的系统调用分发表和 dispatcher，
  `hook/tp_marker.c` 还涉及每任务标记、追踪者并存、32 位 compat syscall。

实验步骤：
1. 构建 `tools/probe_tracepoint_419.sh`（只读）审计 Kconfig、tracepoint 回调签名、
   优先级注册 API、ARM64 syscall entry/exit、compat syscall、静态符号/导出、
   `CONFIG_KPROBES`、异常/RCU 锁行为；证据未全覆盖则不启用。
2. 优先实现**独立的 EXP TP 后端**，与 Manual Hook 配置互斥；
   如果内核缺少等价的安全注册/重定向接口，做小范围 4.19 适配，
   **不得仅绕过上游版本检查**。
3. 验证 ABI `arm64`+32 位 `compat`、`execve`/`execveat`/`setresuid`、
   `stat`/`faccessat`、模块加载、SELinux 和其他 ftrace/perf/eBPF 使用者；
   对追踪点并发卸载、dispatcher 失效、失败回退做负面测试。
4. 单独 EXP 构建并测试真机；出现 panic/权限绕过/启动异常时保持 Manual Hook，
   不合入正式 Standard。

不要为了“Tracepoint”直接拼接 5.10 的系统调用/entry 实现进 4.19；
API 存在不等于可以安全地编辑系统调用号或内核代码页。

## 3. WireGuard / Linux 4.19

采用 [WireGuard/wireguard-linux-compat](https://github.com/WireGuard/wireguard-linux-compat)
作为候选移植来源（声明支持 3.10—5.5；上游正式源在 git.zx2c4.com）。
优先 **内建** `CONFIG_WIREGUARD=y` 的独立 EXP 分支：
OnePlus 6 defconfig 含 `CONFIG_MODULE_SIG_FORCE=y`，
盲目追加未签名 `.ko` 不满足已有内核模块策略。

要验证 4.19 对应的 crypto / UDP tunnel / routing / genetlink / netfilter
依赖与 backport 层是否重复定义，编译并用 `wg`、`ip`、
Android VpnService 分别做握手、IPv4/IPv6、漫游、MTU、长时间休眠/断流测试。
不得把 WireGuard 应用用户态支持误记为内核驱动已就绪。

## 4. BakaSU Toolkit

`CONFIG_KSU_TOOLKIT_SUPPORT` 在 pinned BakaSU 中存在（默认 `n`），
支持特定 supercall 扩展，包括 Manager UID、KernelSU 版本、uname、
标志调整等；这些操作具有安全和一致性风险。

**候选但默认关闭**：限定开发构建启用，并先确认工具端
[backslashxx/ksu_toolkit](https://github.com/backslashxx/ksu_toolkit)
与 pinned BakaSU UAPI 一致；验证 UID 来源、权限边界、版本一致性、
恢复默认与多管理器切换。禁止因便于兼容而默认开启绕过身份校验的接口。

## 5. FuseFixer / 默认可忽略码点问题

来源：[5ec1cff/FuseFixer](https://github.com/5ec1cff/FuseFixer)。
该问题涉及 Android **MediaProvider FUSE Daemon** 与底层 f2fs/ext4 的
casefold/Unicode 规范化不一致：需要优先评估目标 ROM 的
MediaProvider、FUSE、sdcardfs/FUSE BPF、casefold 配置。

优先作为独立 **用户空间 LSPosed 兼容模块**研究；
内核侧仅在确认真实根因和对应 VFS 行为后尝试最小补丁。
该项目自身说明 FUSE BPF 仍有不能完全修复的泄露风险；
不能声称“一条内核补丁就把所有零宽字符问题解决”。
验证不同 UID、用户空间可见性、Android/data、合法路径读写、
casefold 等价路径及回归误报；不得绕开 Android 的正常存储访问控制。

## 分阶段验收门槛

| 阶段 | 交付物 | 通过标准 |
| --- | --- | --- |
| P0（当前） | BakaSU Standard 无 SuSFS 基线 | 已通过 CI + 产物核验；**尚缺真机启动与 Root 回归** |
| P1 | 四管理器认证/协议兼容 EXP | 真实 APK 验签；四者同时安装可识别，安装/卸载/切换无越权，冲突写入安全失败 |
| P2 | WireGuard 4.19 EXP | 编译+路由+握手+漫游+休眠+真机网络实测 |
| P3 | Toolkit 可选 EXP | 安全授权/版本/恢复测试；默认关闭 |
| P4 | MediaProvider FUSE 独立兼容组件 | ROM 级差异验证、Android/data 访问控制回归；不默认进内核 |
| P5 | TP 4.19 EXP | API 契约/32 位兼容/tracepoint 竞争/真机回归通过后再讨论切换 |

**每一阶段独立 CI/产物，不让 EXP 覆盖 Standard；PowerSave 继续不纳入 BakaSU 开发线。**

## 参考源码

- https://github.com/Baka-SU/BakaSU/blob/main/kernel/Kconfig
- https://github.com/Baka-SU/BakaSU/blob/main/kernel/manager/apk_sign.c
- https://github.com/Baka-SU/BakaSU/blob/main/kernel/manager/manager.c
- https://github.com/Baka-SU/BakaSU/blob/main/kernel/hook/syscall_hook_manager.c
- https://github.com/KernelSU-Next/KernelSU-Next/blob/main/kernel/Kbuild
- https://github.com/SukiSU-Ultra/SukiSU-Ultra/blob/main/kernel/Kbuild
- https://github.com/WireGuard/wireguard-linux-compat
- https://github.com/5ec1cff/FuseFixer
- https://github.com/backslashxx/ksu_toolkit
