# OnePlus 6 Android 17 — 2026-11-01 CompatExp fastboot regression

## Status

- **Physical result:** User reported CompatExp boot immediately returns to Fastboot.
- **Confirmed:** CI built, uploaded, and ZIP CRC passed; **boot did not**.
- **Do not deploy** previous `ABK_OnePlus6_BakaSU_CompatExp_cad392026e27_20261101-1230.zip`.
- Recovery baseline: user reported boot success with pinned v0.2 BakaSU boot image
  SHA256 `c763d08e6b686ffbcac3f3730fdf98e0a290c39662fef366369d2cb8255ee432`.
  Prior ROM image only; current installed ROM build and slot remain unconfirmed.
- No SuSFS, no PowerSave; 4.19 Tracepoint and FuseFixer never enabled in the failed build.

## Reproduced artifact differences

| Detail | Booted v0.2 BakaSU | Failed CompatExp | Finding |
|---|---|---|---|
| Source kernel | `Zhanfg/android_kernel_oneplus_sdm845` BakaSU manual-hook, Android 17 | `ZhanfgBuild/kernel_oneplus_sdm845@cad392026e27` | **different source/config baseline** |
| Build config | `vendor/sdm845-perf_defconfig` + `vendor/enchilada.config` (previous v0.2 baseline) | `vendor/enchilada_defconfig` | do not assume ABI/driver equivalent |
| Appended DTBs | 3 verified FDTs | 3 FDTs of different sizes/byte hashes and order | **confirmed mismatch** |
| DTB `/chosen/bootargs` | includes `rcupdate.rcu_nocbs=0-7`, `cgroup.memory=nokmem,nosocket`, `kpti=0`, `ssbd=force-off` | only `rcupdate.rcu_expedited=1` | possible early-boot behavioral difference |
| Image.gz-dtb size | 22,713,984 | 21,383,112 | compiled core+DTBs changed |

Booted v0.2 ROM-order DTB SHA256:
1. `341e34eb0dae79a33a4b2a5cb89cb1f2fb2209d9d17d98f2d04d2551f46c9b11`
2. `da668c914c0db8d8a52917070bfa370dd3208846f731aead4d72b3324b846298`
3. `86638511847918077c2647a125991c03d46e2ecac66f65605c4ddb449774013c`

Failed EXP DTB SHA256:
1. `0f1c3faba95cb2f320329411d4e5507bcc0a33dff23b1252b41b176d99c59fdf`
2. `566b7939f2cdf77a24990b34a88e00ab61ab18974417ea8518cf1057967b2c59`
3. `a5f282ca0e975d8db3f2946e83e06ae1b9e64363fea45825e7787cfd1449ed93`

**Causation not yet proven:** changed DTBs, kernel code, boot-image repacking/AVB and
other runtime differences remain candidate causes. No panics/early console log provided yet.

## Completed offline isolation test image (NOT a flashable release)

Private local repack uses an original 64MiB ROM Boot, the booted v0.2 Boot,
and the exact failed EXP ZIP. None of these ROM Boot binaries are committed.
- **Baseline round trip:** repacking the booted v0.2 Image.gz-dtb into original ROM Boot
  produces a new 64MiB Boot **bit-for-bit identical** to user-tested v0.2,
  including Boot v1 header ID, identical ramdisk, AVB algorithm NONE,
  salted SHA256 descriptor, padding and footer.
- **DTB isolation:** replace **only** the failed EXP Image.gz-dtb's three appended
  FDTs with the booted v0.2 exact ROM-order bytes; keep failed EXP **gzip
  kernel** byte-identical. Recreate the full 64MiB boot-v1/AVB image from the
  same original ROM template. Output checksum:
  `839a188386e79babd23e73209ed91ce66966fbe56ed8971c4e53d70245ce545e`.
- This candidate is **unbooted and unverified**. Only offer
  `fastboot boot <image>` temporary startup once the matching v0.2 environment
  is restored and the bootloader supports temporary boot. **Never flash it.**
- If it still fails, priority shifts to the incompatible kernel source and/or
  BakaSU/Toolkit runtime; do not label DTB replacement a fix.
- Stock AOSP Recovery sideload cannot install an unsigned AK3 ZIP.

## CI policy

- New `scripts/check_op6_rom_dtb.py` fails closed on any unknown, duplicated,
  missing or reordered FDT before uploading a **new** CompatExp AK3.
- Change build source to verified `Zhanfg/android_kernel_oneplus_sdm845`
  with the `sdm845-perf_defconfig` + `enchilada.config` merge path,
  and run a staged one-feature-at-a-time compile; preserve current known-good
  boot image for recovery.
- Verify the build's ramdisk and AVB using an **exact matching ROM original**
  instead of relying on a generic unguarded `dump_boot/write_boot`.
- Until real temporary boot success, do **not** publish another unguarded
  flashable AK3 or claim stable/fully functional four-manager compatibility.

## Minimal real-device validation

1. First restore booted v0.2 via matching ROM Boot (if necessary) and verify
   Android boots normally, with correct ROM and slot.
2. From a host using the bootloader, optional **temporary only** test:
   `fastboot boot OnePlus6_A17_BakaSU_CompatExp_DTB_Isolation_FASTBOOT_ONLY.img`.
   If Fastboot rejects temporary boot, STOP, do not switch to `flash`.
3. Record whether failure is pre-logo, logo/hang, Fastboot return,
   recovery, or Android partially boots; where available capture non-sensitive
   `pstore/console-ramoops` on the next successful boot.
4. Only after successful boot / Root / radio / storage tests, discuss an
   AK3 package gated to the exact installed ROM build/boot SHA and active slot.

The past CI result was sufficient for binary integrity, **not** boot safety.
