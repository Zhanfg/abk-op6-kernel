# OnePlus 6 Android 17 — v0.2 Root regression (2026-11-01)

## Update from 2026-11-01 22:56:54 device diagnosis — PRIORITY

The user supplied `OP6_BakaSU_Rootless_Diag_20261101_225654.txt`.

- Current Android 17 OnePlus 6 is booted from **slot `_a`**.
- **Actually running** `uname -r`:
  `4.19.325-cip136-st20-perf-gfd77fc2e307e-dirty`.
- **Archived v0.2 BOOT_USER_TESTED.img actual embedded kernel release**:
  `4.19.325-cip136-st20-perf-g9ad0027fcccb-dirty`.
  These values differ: the archived v0.2 Boot is NOT the currently running kernel.
  This is the first item to resolve before attributing Root failure to v0.2 itself.
- The current runtime commit ID `fd77fc2e307e` matches an upstream OnePlus 6
  kernel commit which has no KernelSU source integration in `kernel/reboot.c`,
  `drivers/Kconfig`, or `drivers/Makefile` at that exact commit.
  A dirty downstream build could differ; without current boot.img bytes, **do not**
  conclusively assert KernelSU is missing on the device.
- **Earlier diagnostic script contained a genuine package-name bug.**
  The BakaSU Gradle `namespace` is `org.bakasu.bakasu` but its default
  APK `applicationId` is **`com.resukisu.resukisu`**, which the original
  script did not query. Its six `not-found` lines are consequently **not**
  reliable evidence of absence. Android shell PackageManager access may
  independently be restricted.
- `/proc/version` returned permission denied and no KernelSU init lines
  were obtained. These are unavailable observations, not negative evidence.
- The user reports BakaSU UI opens but says KernelSU not compiled; this
  observation now applies to the **actually running `gfd77fc2e307e` kernel**,
  not a byte-confirmed v0.2 boot.
- The true next gate is to establish the source and SHA of **current slot A
  Boot**, or temporarily boot the verified v0.2 Boot with
  `fastboot boot <verified-v0.2.img>` **only if the ROM baseline still matches**.
  Do not perform unconditional `fastboot flash`, wipe data, modify vbmeta,
  or lock the bootloader.
- Check `com.resukisu.resukisu` with a corrected no-root script and verify
  its signing certificate/UAPI only **after** confirming the expected kernel
  is running.

**Correction:** Prior "v0.2 boot succeeds, Root fails" was too strong:
the latest live evidence cannot establish a Root regression of the archived
v0.2 image, because the running kernel is different.

---

## User-reported runtime result

- **Boot:** v0.2 boot image starts Android successfully.
- **Root:** BakaSU Manager reports kernel not installed/compiled and cannot get Root.
- **Correct status:** v0.2 is **boot-success-only**, not a stable usable Root rollback.
- **Never prescribe the failed CompatExp as a replacement:** it returned to Fastboot and was not boot tested.

## What is actually verified

- Archived v0.2 `OnePlus6_A17_BakaSU_4.19.325_v0.2_BOOT_USER_TESTED.img`
  SHA-256 `c763d08e6b686ffbcac3f3730fdf98e0a290c39662fef366369d2cb8255ee432`.
- This complete Boot contains a Linux 4.19.325 compressed kernel with ~360
  `KernelSU` debug/feature strings, including `ksu` ioctl, selinux,
  manager detection and ksud integration, that **do not exist** in the original
  unrooted ROM Boot. Therefore, absence of compiled code is not the right diagnosis.
- Source tree for its earlier build: `Zhanfg/android_kernel_oneplus_sdm845`,
  BakaSU pinned SHA `5b76b884c75f729a220bb317aa4a4fc78f0e0e9c`,
  validated source workflow run
  https://github.com/Zhanfg/android_kernel_oneplus_sdm845/actions/runs/38107371899
  logs `BakaSU version code: 35222`, `using Manual Hook`,
  and compiled `drivers/kernelsu/core/init.o`,
  `drivers/kernelsu/supercall/supercall.o`,
  `drivers/kernelsu/manager/apk_sign.o`.
- BakaSU Manager current `Natives.MINIMAL_SUPPORTED_KERNEL = 35002`.
  Thus 35222 is **not** obviously below the configured minimum supported
  version. **Real Manager recognition remains untested**.
- Source contains Manual Hook in `kernel/reboot.c` invoking
  `ksu_handle_sys_reboot(...)` before ordinary Linux reboot permission checks.
  Static hook presence cannot establish actual runtime transport functionality.
- BakaSU Manager `KernelRepository.getStatus()` obtains
  `Natives.isManager`, and returns `ksuVersion=null` whenever that is
  false. Its Home UI then displays the non-working status on non-GKI kernels.
  So it may say "not installed/unsupported" even when a driver binary exists.

## Working hypotheses (not yet diagnosed)

1. The installed Manager APK's actual signing certificate/variant does not
   match the kernel's pinned BakaSU / official KernelSU allowlist.
2. Manual Hook's reboot FD transport or the BakaSU initcall does not function
   in the running kernel despite being linked.
3. The currently booted A/B slot has a different boot/kernel than the image
   inspected offline.
4. Old kernel UAPI and newer Manager userspace protocol disagree, or the
   Manager is not registered correctly after APK update.

## Verification before any new flash

- Run `OP6_BakaSU_Rootless_Diag.sh` (plain Android sh, no parameters, no Root,
  no Termux) to capture device/slot, package versions and any accessible
  KernelSU init messages. No full property dump or other private app contents.
- Compare the *installed* BakaSU APK certificate hash with expected
  `0x377:d3469712b6214462764a1d8d3e5cbe1d6819a0b629791b9f4101867821f1df64`;
  a repackaged APK might use a different signer.
- If Manager recognizes backend but cannot grant Root, inspect
  `ksu` SELinux policy, `ksud` userspace state, app profile and supercall
  grant root return codes; do not equate this with signature rejection.
- Never disable Manager signature verification or grant arbitrary UID Root as
  a workaround. Test one exact certified Manager APK and UAPI at a time.
- New builds must assert presence of
  `kernelsu_init`, `ksu_handle_sys_reboot`, `ksu_install_fd`,
  `ksu_is_manager_appid` and runtime-related code symbols; still require
  actual device init and Manager permission regression checks.

## Release gates

v0.2's usable daily driver flag is hereby **withdrawn**.
Neither the previous v0.2 AK3 nor the new CompatExp AK3 can be considered a
verified working Root kernel. A future bootable rescue image must be tested for
Android boot **and** recognition by BakaSU / Root grant / ksud + modules.
