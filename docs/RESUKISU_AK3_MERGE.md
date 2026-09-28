# ReSukiSU AK3 legacy builder consolidation

This repository is the canonical OnePlus 6 build/release orchestration repository.

## Repository roles

- Canonical builder: `Zhanfg/abk-op6-kernel`
- Legacy builder: `Zhanfg/resukisu_ak3`
- Kernel source boundary: `ZhanfgBuild/kernel_oneplus_sdm845`

The kernel source remains a separate repository. No kernel source tree is copied into this builder.

## Legacy audit

The useful legacy work is on `Zhanfg/resukisu_ak3:review/reproducible-resukisu-build`, which is 16 commits ahead of the legacy `main` branch.

The consolidation imports the reusable engineering ideas from that branch:

- fail-fast source-contract validation;
- shell script linting and synthetic contract tests;
- exact/pinned build inputs and source provenance;
- deterministic metadata and SHA256 verification;
- explicit separation of Build Verified from Boot/Runtime Verified.

The legacy Linux 4.9 integration script is intentionally **not** copied. It rewrites a 4.9 source tree, creates `drivers/kernelsu`, and enables 4.9-specific manual auto-hook options. The current OnePlus 6 source is Linux 4.19 and already contains ReSukiSU/SuSFS integration, so importing that mutating integration path would violate the source/build repository boundary.

The unrelated `linear-zh-lsposed` branch is also not imported.

## Current validation contract

Before either Standard or PowerSave builds continue, CI now verifies that the checked-out source:

- identifies as Linux 4.19;
- contains the active `drivers/kernelsu` Kbuild/Kconfig wiring;
- contains SuSFS source/header integration;
- enables the required ReSukiSU/SuSFS config contract in the OnePlus 6 defconfig.

The validator is read-only. PowerSave remains the only build path that modifies the checked-out defconfig, and it does so through the existing PowerSave patch.

## Artifact contract

Both build variants continue to generate and check:

- `Image.gz-dtb`;
- rebuilt `dtbo.img`;
- AnyKernel3 ZIP;
- ZIP SHA256;
- `BUILD_INFO.txt`;
- `BUILD_METADATA.sha256`;
- `DTBO_FILES.txt`;
- final `kernel.config`.

A successful CI run is **Build Verified only**. Boot Verified and Runtime Verified still require OnePlus 6 device testing.
