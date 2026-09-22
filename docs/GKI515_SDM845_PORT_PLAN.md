# OnePlus 6 / SDM845 — Android 14 GKI 5.15 port plan

## Goal

Bring OnePlus 6 (`enchilada`) to an Android 14 / Linux 5.15 GKI-style kernel while keeping the Android 17 userspace and the original device partition layout recoverable.

The 4.19 tree remains the runtime oracle until this line reaches feature parity.

## Donor hierarchy

| Layer | Primary source | Purpose |
|---|---|---|
| Generic kernel / KMI | Android ACK `common-android14-5.15-2026-07` | GKI core, KMI, security/stable base |
| SDM845 upstream infrastructure | `sdm845-mainline/linux` + upstream Linux | clocks, regulators, pinctrl, interconnect, SMMU/IOMMU, UFS, remoteproc, DT structure |
| Android Qualcomm 5.15 patterns | CodeLinaro `kernel/msm-5.15` and open kernel modules | Android module split, Qualcomm-specific interfaces, graphics/display module architecture |
| OP6 Android behavior | current OnePlus 6/SDM845 4.19 tree | board quirks, panel/touch/fingerprint behavior, legacy vendor ABI expectations |
| Firmware / proprietary userspace | final OxygenOS firmware/blobs already used by the ROM tree | modem/DSP/TZ and proprietary HAL compatibility |

Do not bulk-port the 4.19 Qualcomm kernel into ACK 5.15. Prefer upstream 5.15 implementations where they can satisfy the hardware and ABI contract, then add only the Android/OnePlus-specific delta.

## Major compatibility constraint

Mainline SDM845 support is useful for platform bring-up, but it is not automatically a drop-in replacement for the Android vendor stack.

The existing proprietary Android graphics userspace expects Qualcomm Android interfaces such as KGSL. Therefore:

- use upstream/mainline SDM845 code aggressively for generic SoC infrastructure;
- retain or port a compatible Qualcomm Android graphics path for the proprietary Android userspace;
- do not declare GPU/display complete merely because a mainline DRM/MSM desktop Linux stack can light the panel.

The same rule applies to camera, audio and WLAN: upstream drivers are valuable donors, but the final kernel interface must match the Android HAL/blob contract actually used by the ROM.

## Bring-up stages

### G0 — build/KMI

- [x] Build ReSukiSU as `android14-5.15` LKM
- [ ] Build canonical arm64 GKI distribution with Kleaf
- [ ] Archive `Image`, `vmlinux.symvers`, module metadata and pinned manifest
- [ ] Establish KMI symbol audit for all future OP6 vendor modules

### G1 — boot substrate

Port/enable only what is required to reach first-stage init:

- SDM845 DT + OP6 board DT
- PMIC/regulators
- clocks
- pinctrl/GPIO
- interconnect
- SMMU/IOMMU
- UFS
- timer/interrupts
- console/pstore
- USB enough for early ADB

Target:

```text
bootloader -> GKI Image -> init -> mount system/vendor -> ADB
```

No GPU, camera or radio requirement at this stage.

### G2 — OP6 boot-image bridge

OnePlus 6 predates the modern `vendor_boot` / `vendor_dlkm` layout. Early bring-up must not modify GPT.

Initial strategy:

1. retain the existing boot partition layout;
2. repack the 5.15 kernel into an OP6-compatible boot image;
3. keep mandatory early modules in the boot ramdisk when required;
4. place ordinary device modules in the existing vendor filesystem and load them in deterministic dependency order;
5. keep DT/DTBO layout compatible with the bootloader;
6. do not introduce new physical partitions during bring-up.

A later product can emulate a cleaner modern module layout at the filesystem/build level without repartitioning the device.

### G3 — display/input

Order:

1. panel + DSI/display controller
2. framebuffer/composer-visible display path
3. touchscreen
4. KGSL-compatible Adreno 630 path
5. validate EGL/Vulkan userspace

Display and GPU are separate gates.

### G4 — core connectivity

- WLAN
- Bluetooth
- USB modes
- audio
- sensors
- GPS
- NFC

### G5 — difficult proprietary stacks

- camera
- fingerprint
- modem/RIL/IMS runtime validation
- suspend/deep idle
- charging/thermal
- remaining OnePlus-specific nodes

## Vendor-module rules

Every module added to the 5.15 device layer must record:

- source repository + exact SHA/tag;
- whether the implementation is upstream, Qualcomm/CLO, Lineage/OP6-derived or locally adapted;
- required KMI symbols;
- module dependency order;
- firmware files used;
- runtime node/interface consumed by Android userspace.

A module does not pass merely because it compiles. Required states are:

```text
Build Verified
  -> Symbol/KMI Verified
  -> Load Verified
  -> Hardware Probe Verified
  -> Android HAL Verified
  -> Runtime Verified
```

## ReSukiSU

The GKI path uses the external LKM contract:

```text
KMI: android14-5.15
CONFIG_KSU=m
CONFIG_KSU_TRACEPOINT_HOOK=y
```

Do not fold ReSukiSU back into the generic GKI source solely to obtain root. Keeping it as an LKM preserves a cleaner GKI core and makes KMI failures explicit.

## Safety / rollback

- 4.19 remains the known-good rollback kernel.
- Generic GKI artifacts are not OP6-flashable until G2 is complete.
- Do not touch GPT in G0–G3.
- Never commit signing keys, EFS/NV/calibration data or device identifiers.
- Keep boot and runtime verification separate from compile verification.
