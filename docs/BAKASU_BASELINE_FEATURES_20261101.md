# OnePlus 6 — BakaSU baseline without SuSFS

## Scope

- Device: OnePlus 6 (enchilada), Linux 4.19.325.
- BakaSU pinned to `516d3e87fbc986ccefdde2c2765f1700612441a9`.
- Root mode: **CONFIG_KSU_MANUAL_HOOK=y**. This is the Linux 4.19-supported hook path.
- **SuSFS disabled**: `CONFIG_KSU_SUSFS` and all `CONFIG_KSU_SUSFS_*` are removed from the BakaSU build config. Legacy kernel SuSFS source files may remain in the source tree but are not compiled or packaged into the BakaSU build.
- BakaSU Dynamic Manager and multi-manager functionality are retained. Runtime management still requires matching userspace Manager and ksud.
- Existing ReSukiSU PowerSave workflow is a distinct legacy variant; it is not the requested new baseline.
- No performance tuning or FUSE/zero-width changes in the baseline.

## Verification

The workflow checks effective `out/.config`, forbids enabled SuSFS symbols and `out/fs/susfs.o`, checks BakaSU `dynamic_manager.o`, `throne_tracker.o`, and built-in archive symbol `ksu_handle_dynamic_manager`. Build artifact names and AnyKernel3 label do not claim SuSFS for BakaSU.

Passing CI means only that the kernel compiles, links, and packages. Device boot, root privilege behavior, system compatibility, and Manager persistence require physical testing. Keep the original boot image for rollback.

## History

Initial integration incorrectly required the SuSFS inline hook; the original baseline request did not. A missing SuSFS thread helper caused an earlier linker failure, and then an overstrict check expected an intermediate `kernelsu.o` that Linux 4.19 Kbuild did not emit. Both were addressed by removing SuSFS from the BakaSU build and validating the actual built-in archive instead of a nonexistent intermediate object.
