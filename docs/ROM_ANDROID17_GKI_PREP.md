# OnePlus 6 Android 17 / GKI ROM — pre-bring-up plan

## Goal

Build an independent OnePlus 6 (`enchilada`, SDM845) ROM with these constraints:

- Userspace base: **AOSP Android 17**, not LineageOS.
- No LineageOS runtime/build identity in the final ROM.
- Primary kernel target: **GKI 2.0 / Linux 5.15**.
- 5.10 may be used only as an experimental bridge; it is not the long-term target for Android 17 QPR1+.
- Root: **KernelSU LKM**.
- Verified Boot: **AVB 2.0 with our own custom key**, with the bootloader intended to remain locked for normal use.
- Storage: modern dynamic-partition layout where useful (`super`, `metadata`, `system_dlkm`, `vendor_dlkm`, etc.), while preserving OP6 boot-chain compatibility until a separate bootloader study proves more is safe.
- UI/customization: Evolution X-like feature set may be ported later, but Evolution X/LineageOS are **reference sources only**, not the base ROM.

## Frozen baselines

### Android userspace

- AOSP manifest: `https://android.googlesource.com/platform/manifest`
- Baseline tag: `android-17.0.0_r1`
- Baseline manifest commit: `5bc9a7ce1cd78dd53613bbfd0ebf506e1e4adb0f`

### Primary GKI target

- Android kernel manifest: `https://android.googlesource.com/kernel/manifest`
- Bring-up branch: `common-android14-5.15-2026-07`
- Frozen kernel/common reference tag: `android14-5.15-2026-07_r2`
- `kernel/common` commit for that tag: `94fbb8c6595740927376fc346c53e9c8868067dd`

Android 17 officially supports both `android13-5.15` and `android14-5.15`. 5.10 is not the long-term target because Android 17 QPR1+ drops support for the 5.10 GKI lines.

### Existing OP6 hardware references

1. `Zhanfg/kernel_oneplus_sdm845`
   - Current ABK 4.19 hardware reference.
   - Frozen branch created for this project: `reference/4.19-freeze-20260917`.

2. `EdwinMoq/android_kernel_oneplus_sdm845`
   - Branch: `lineage-23.2-4.19`.
   - Treat as a known-good Android/OP6 hardware behavior reference, not as the 5.15 base.

3. `OnePlusOSS/android_kernel_oneplus_sdm845`
   - Official old Linux 4.9 OnePlus source.
   - Historical hardware/driver reference only.

4. Linux mainline SDM845 / OnePlus 6 DTS
   - Used to study modern upstream implementations of clocks, interconnect, UFS, IOMMU, USB, DRM/MSM, power domains, thermal, etc.

## Repositories to fork now

Only fork repositories we expect to edit directly. Do **not** fork every upstream dependency.

### Required

1. `LineageOS/android_device_oneplus_enchilada`
   - Target fork name: `Zhanfg/android_device_oneplus_enchilada`
   - Purpose: extract hardware facts, board configuration, init/fstab/VINTF/SEPolicy/device-specific behavior.
   - First cleanup task: remove Lineage product inheritance and all Lineage-specific identity/dependencies; convert it into an AOSP-owned device tree.

2. `LineageOS/android_device_oneplus_sdm845-common`
   - Target fork name: `Zhanfg/android_device_oneplus_sdm845-common`
   - Purpose: shared SDM845 OnePlus hardware/HAL/device configuration reference.
   - Same rule: keep hardware enablement, remove Lineage build/runtime identity.

### Already available — do not fork again

3. `Zhanfg/kernel_oneplus_sdm845`
   - Existing 4.19 hardware reference.

4. `Zhanfg/KernelSU`
   - Existing KernelSU fork; use only after the GKI module-loading path is functional.

5. `Zhanfg/abk-op6-kernel`
   - For now this repository is the control/bring-up notebook and CI staging area.

### Optional later

6. `EdwinMoq/android_kernel_oneplus_sdm845`
   - Fork only if we want Git ancestry and upstream comparison preserved as a dedicated reference fork. Not needed to begin because our existing 4.19 tree is already frozen.

## Repositories NOT to fork now

### AOSP

Do not fork the entire AOSP tree. `repo` should continue to pull untouched projects directly from AOSP. When we actually modify a platform repository, create our own mirror for that specific component only.

Likely future owned platform mirrors:

- `frameworks/base`
- `packages/apps/Settings`
- `packages/apps/Launcher3`
- possibly `frameworks/native`

Do not create these until a real patch requires them.

### Evolution X / other ROMs

Do not fork Evolution X as our base. Later we may inspect/cherry-pick/reimplement individual features from:

- `frameworks/base`
- SystemUI
- Settings/Evolver
- Launcher
- overlays/vendor customization

Each feature must be reviewed for Lineage-specific APIs before porting.

### Proprietary vendor blobs

Do not make TheMuppets repositories the authoritative vendor source. They are useful read-only references:

- `TheMuppets/proprietary_vendor_oneplus_enchilada`
- `TheMuppets/proprietary_vendor_oneplus_sdm845-common`

Long term, generate our own `vendor/oneplus/...` tree from a pinned OnePlus/OOS firmware baseline using extraction scripts. This makes the blob provenance explicit and avoids tying the ROM identity to Lineage infrastructure.

## Reference-only checkout policy

The local manifest in `manifests/op6-reference.xml` deliberately places Lineage/Edwin/OnePlusOSS/TheMuppets sources under `reference/...`, not under active Android build paths.

That is intentional:

- prevents an accidental LOS-based build;
- lets us diff hardware facts against our clean AOSP device tree;
- makes provenance obvious during review.

## First computer session

Run:

```bash
./scripts/bootstrap-aosp17-op6.sh ~/android/op6-rom
```

It will initialize two workspaces:

```text
~/android/op6-rom/
├── aosp17/      # AOSP android-17.0.0_r1 + read-only OP6 references
└── gki-5.15/    # Android kernel manifest, 5.15 GKI toolchain/tree
```

Do not start by importing Evolution X patches.

## Phase 0 — first deliverable

The first goal is **not a polished ROM**. It is a clean AOSP 17 device bring-up skeleton with explicit provenance.

Deliverables:

1. `device/oneplus/enchilada` — clean AOSP-owned tree.
2. `device/oneplus/sdm845-common` — clean AOSP-owned common tree.
3. `vendor/oneplus/...` — generated/pinned blob tree.
4. GKI 5.15 build reproduces with exact source tag/toolchain metadata.
5. OP6 boot-image compatibility design documented before flashing.
6. AVB key hierarchy documented; no production private keys stored in Git.
7. Partition proposal documented but **no GPT writes** until the existing six-LUN layout is dumped/verified.
8. Boot target: kernel reaches init/ADB. Camera/IMS/audio are not Phase-0 blockers.

## Non-negotiable safety rules

- Never commit AVB private keys, module signing keys, API tokens, device serials, EFS/NV/calibration dumps, or other secrets.
- Keep modem/NV/calibration partitions (`fsg`, `fsc`, `modemst*`, `persist`, etc.) outside experimental repartitioning.
- A build that compiles is not considered boot-verified.
- Keep the current 4.19 kernel and known restore path intact until the GKI tree boots on-device.
- LineageOS source may be used as a hardware reference, but Lineage product inheritance, package namespaces, properties, updater/recovery identity and framework APIs must not become dependencies of the final ROM.
