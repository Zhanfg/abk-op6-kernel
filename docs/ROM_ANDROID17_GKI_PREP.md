# OnePlus 6 Android 17 / dual-kernel bring-up

## Current objective

The project is now split into two parallel tracks:

1. **Phase-1 ROM:** Evolution X `cnb` / Android 17 on the known-good OnePlus 6 Linux 4.19 hardware stack.
2. **Parallel kernel:** Android GKI 2.0 / Linux 5.15 with ReSukiSU LKM, followed by SDM845/OnePlus 6 bring-up.

The clean AOSP 17 path is retained for the later independent/de-identified product layer; it is no longer the shortest path to the first bootable Android 17 test build.

## Active repositories and branches

| Layer | Repository | Branch |
|---|---|---|
| Device | `Zhanfg/android_device_oneplus_enchilada` | `bringup/evox17` |
| Common device | `Zhanfg/android_device_oneplus_sdm845-common` | `bringup/evox17` |
| OnePlus hardware | `Zhanfg/android_hardware_oneplus` | `bringup/evox17` |
| Legacy kernel source | `Zhanfg/kernel_oneplus_sdm845` | `legacy-4.19-a17` |
| Clean future device path | same device repositories | `bringup/aosp17` |
| Control / CI | `Zhanfg/abk-op6-kernel` | `prep/android17-gki-rom` |

## Phase 1A — first Android 17 boot

Base:

- Evolution X manifest: `cnb`
- Lunch: `lineage_enchilada-cp2a-userdebug`
- Build target: `m evolution`
- Kernel: Linux 4.19 from `legacy-4.19-a17`

The `bringup/evox17` device branch intentionally retains the known-good Lineage/Evolution hardware-facing services, overlays, VINTF matrix and development AVB flags. These are bring-up dependencies, not the final product identity.

Success order:

1. source sync
2. product/lunch resolution
3. Soong/Kati generation
4. kernel + dtbo build
5. boot image generation
6. first-stage init
7. ADB
8. SurfaceFlinger
9. SystemUI / launcher

Only after that do we close the hardware matrix: UFS, display/touch, GPU, Wi-Fi, BT, audio, RIL/IMS, sensors, fingerprint, GPS, camera, NFC, charging, thermal and suspend.

## Legacy 4.19 role

The 4.19 tree is not the long-term kernel target. It is the **known-good hardware oracle and rollback path**.

It already contains ReSukiSU and SuSFS. The dedicated ROM build is pinned to:

`Zhanfg/kernel_oneplus_sdm845@legacy-4.19-a17`

This prevents later `master` changes from silently changing the ROM kernel baseline.

## Parallel GKI 5.15 track

Baseline:

- kernel manifest: `https://android.googlesource.com/kernel/manifest`
- branch: `common-android14-5.15-2026-07`
- architecture: arm64
- ReSukiSU mode: `CONFIG_KSU=m`
- hook: `CONFIG_KSU_TRACEPOINT_HOOK=y`

The first GKI milestone is only **Build Verified**:

- `Image`
- `kernelsu.ko`
- `vmlinux.symvers`
- `modules.builtin`
- pinned manifest and SHA256 provenance

These artifacts are **not flashable on OnePlus 6 yet**.

The OP6 GKI boot milestone additionally requires:

- boot image layout bridge
- DT/DTBO strategy
- early firmware loading
- SDM845 clocks/regulators/interconnect/power domains
- SMMU/IOMMU
- UFS
- display/GPU
- vendor module loading
- first-stage init / ADB

## Source bootstrap

Run:

```bash
./scripts/bootstrap-evox17-op6.sh ~/android/op6-rom
```

It creates:

```text
~/android/op6-rom/
├── evox17/
├── gki-5.15/
├── evox17-pinned-manifest.xml
└── gki515-pinned-manifest.xml
```

## CI

- `OP6 EvoX17 Preflight`: validates source topology and active branches.
- `Build A17 Legacy 4.19`: reproducible ROM-stage 4.19 kernel build.
- `Build ReSukiSU GKI 5.15`: GKI build/KMI artifact pipeline.

A compile pass is not equivalent to a device boot pass.

## Later clean product / de-identification

After the EvoX + 4.19 baseline boots reliably:

1. move hardware enablement back toward `bringup/aosp17`;
2. remove unnecessary Lineage/Evolution product/runtime identity;
3. replace donor services with ROM-owned/AOSP-facing implementations;
4. define independent release product/vendor configuration;
5. introduce release signing and the secure AVB profile.

The fast bring-up branch and the clean product branch must remain separate until the latter reaches hardware parity.

## Safety rules

- Never commit AVB private keys, module-signing private keys, API tokens, EFS/NV/calibration dumps, serials or other secrets.
- Do not modify GPT during early bring-up.
- Preserve the known-good 4.19 boot/recovery path until GKI 5.15 is Boot Verified and Runtime Verified.
- Do not describe generic GKI artifacts as OnePlus 6 flashable images.
