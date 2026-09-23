# OnePlus 6 — GKI 5.15 ReSukiSU + SUSFS bring-up

This is the parallel GKI kernel track for the OnePlus 6 Android 17 project.

## Policy

- Kernel base: Android Common Kernel 5.15, `common-android14-5.15`.
- Root: latest `ReSukiSU/ReSukiSU@main`, resolved to an exact SHA at build time.
- SUSFS: latest `simonpunk/susfs4ksu@gki-android14-5.15`, resolved to an exact SHA at build time.
- ReSukiSU is initially built in (`CONFIG_KSU=y`) for bring-up reliability.
- Hook mode for the SUSFS build is `CONFIG_KSU_SUSFS=y` (SUSFS Inline Hook).
- Exact kernel/ReSukiSU/SUSFS SHAs and detected SUSFS version are stored in `GKI_BUILD_INFO.txt`.

## Why SUSFS Inline Hook

Current ReSukiSU models Tracepoint, Manual Hook and SUSFS Inline Hook as mutually exclusive hook methods. The build that must carry current SUSFS therefore uses ReSukiSU's native SUSFS hook path instead of stacking the legacy KernelSU SUSFS integration patch over ReSukiSU.

A later LKM/tracepoint experiment is allowed only after the OP6 GKI baseline boots and only if it preserves the same SUSFS capability without bypassing compatibility checks.

## Safety gate

The generic GKI `Image` produced here is **not yet flashable on OnePlus 6**.

Before flashing it needs:

1. OP6 boot-image compatibility.
2. SDM845/OnePlus vendor modules built against the same KMI.
3. DT/DTBO integration.
4. UFS/display/early-init boot validation.
5. The known-good 4.19 recovery path retained.

Compile success is only the first gate.
