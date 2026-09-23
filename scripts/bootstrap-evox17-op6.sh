#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$HOME/android/op6-rom}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTROL_REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
EVOX_DIR="$ROOT/evox17"
GKI_DIR="$ROOT/gki-5.15"

EVOX_MANIFEST="https://github.com/Evolution-X/manifest"
EVOX_REVISION="cnb"
KERNEL_MANIFEST="https://android.googlesource.com/kernel/manifest"
KERNEL_REVISION="common-android14-5.15-2026-07"

command -v git >/dev/null 2>&1 || { echo "ERROR: git not found" >&2; exit 1; }
command -v repo >/dev/null 2>&1 || { echo "ERROR: repo tool not found" >&2; exit 1; }

mkdir -p "$ROOT"

printf '\n==> Initializing Evolution X Android 17 workspace: %s\n' "$EVOX_DIR"
mkdir -p "$EVOX_DIR"
cd "$EVOX_DIR"
repo init -u "$EVOX_MANIFEST" -b "$EVOX_REVISION" --git-lfs
mkdir -p .repo/local_manifests
cp "$CONTROL_REPO/manifests/op6-evox17.xml" .repo/local_manifests/10-op6-evox17.xml

printf '\n==> Syncing Evolution X cnb + OnePlus 6 Phase-1 trees\n'
repo sync -c --force-sync --no-tags --no-clone-bundle -j"${SYNC_JOBS:-8}"
repo manifest -r -o "$ROOT/evox17-pinned-manifest.xml"

printf '\n==> Initializing Android 14/5.15 GKI workspace: %s\n' "$GKI_DIR"
mkdir -p "$GKI_DIR"
cd "$GKI_DIR"
repo init -u "$KERNEL_MANIFEST" -b "$KERNEL_REVISION"
repo sync -c --no-tags --no-clone-bundle -j"${SYNC_JOBS:-8}"
repo manifest -r -o "$ROOT/gki515-pinned-manifest.xml"

cat <<'EOF'

Bootstrap complete.

Phase-1 ROM:
  workspace: evox17/
  lunch:     lineage_enchilada-cp2a-userdebug
  build:     m evolution
  kernel:    Zhanfg/kernel_oneplus_sdm845@legacy-4.19-a17

Parallel kernel:
  workspace: gki-5.15/
  baseline:  common-android14-5.15-2026-07
  purpose:   ReSukiSU GKI2 + later OP6/SDM845 bring-up

Important:
  - The 4.19 branch is the boot/reference path until 5.15 is runtime-complete.
  - The GKI artifact is NOT OP6-flashable until boot image, DT/DTBO and vendor
    module compatibility work is complete.
  - Production signing keys and device-specific NV/calibration data must never
    be committed.
EOF
