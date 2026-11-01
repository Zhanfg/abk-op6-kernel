# OnePlus 6 BakaSU baseline: feature and patch scope

## Kernel build

The build workflow tracks BakaSU main at pinned commit `516d3e87fbc986ccefdde2c2765f1700612441a9`. It preserves OnePlus 6 Linux 4.19.325 and the existing defconfig, manual hook, and pre-existing SuSFS source patches. It does not automatically migrate newer GKI-only features or introduce tuning.

### Dynamic Manager

BakaSU already includes `feature/dynamic_manager.c`, manager tracking, and `supercall` support. Unlike a separately applied patch, it is part of BakaSU's built-in kernel sources whenever KernelSU manager integration is enabled.

The workflow verifies the *effective* `out/.config` and the compiled `dynamic_manager.o`, `throne_tracker.o`, and `kernelsu.o` files. A successful source checkout alone does not prove successful compilation.

Dynamic-manager settings are not embedded into the kernel image. The corresponding BakaSU Manager and updated `ksud` provide the configuration UI, user authorization, and persistent reloading from `/data/adb/ksu/.dynamic_manager`. Do not preauthorize or silently switch management packages during the kernel build.

### Unicode zero-width / FUSE

The `drivers/tty/vt/consolemap.c` code's zero-width handling affects the Linux virtual terminal glyph mapper; **it does not fix Android MediaProvider FUSE package-visibility leaks**.

The separate upstream [FuseFixer](https://github.com/5ec1cff/FuseFixer) is an Xposed/LSPosed hook of MediaProvider's FUSE daemon. It cannot be reliably merged by copying a general kernel patch into a Linux 4.19 source tree; it also documents additional FUSE BPF issues that its app hook does not fully solve. It is **not bundled** or automatically enabled, nor is the false claim made that the core kernel alone fixes that Android-level issue.

For device-specific remediation, validate the installed Android MediaProvider, filesystem casefold mode, FUSE/sdcardfs configuration, and existence of FUSE BPF support before attempting any kernel-side backport.

## Build vs boot verification

CI validates compiling the kernel and packaging AnyKernel3; it cannot verify boot, root, dynamic-manager persistence, module mounts, or Android/data access control on the physical phone. Keep the original boot.img for rollback.
