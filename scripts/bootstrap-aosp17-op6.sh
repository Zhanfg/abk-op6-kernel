#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$HOME/android/op6-rom}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTROL_REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
AOSP_DIR="$ROOT/aosp17"
GKI_DIR="$ROOT/gki-5.15"

AOSP_MANIFEST="https://android.googlesource.com/platform/manifest"
AOSP_REVISION="android-17.0.0_r1"
KERNEL_MANIFEST="https://android.googlesource.com/kernel/manifest"
KERNEL_REVISION="common-android14-5.15-2026-07"

command -v git >/dev/null 2>&1 || { echo "ERROR: git not found" >&2; exit 1; }
command -v repo >/dev/null 2>&1 || { echo "ERROR: repo tool not found" >&2; exit 1; }

mkdir -p "$ROOT"

printf '\n==> Initializing OFFICIAL AOSP 17 workspace: %s\n' "$AOSP_DIR"
mkdir -p "$AOSP_DIR"
cd "$AOSP_DIR"
repo init -u "$AOSP_MANIFEST" -b "$AOSP_REVISION"
mkdir -p .repo/local_manifests

# Active product/device layer owned by us.
cp "$CONTROL_REPO/manifests/op6-aosp17.xml" .repo/local_manifests/10-op6-aosp17.xml

# Temporary Qualcomm/CAF compatibility layer. This is intentionally isolated
# from the product identity and can be removed subsystem-by-subsystem later.
cp "$CONTROL_REPO/manifests/op6-qcom-bridge.xml" .repo/local_manifests/20-op6-qcom-bridge.xml

# Reference-only donors (`notdefault`), including Lineage and Evolution X.
cp "$CONTROL_REPO/manifests/op6-reference.xml" .repo/local_manifests/90-op6-reference.xml

printf '\n==> Syncing AOSP 17 + active OP6 + Qualcomm bridge\n'
repo sync -c --no-tags --no-clone-bundle -j"${SYNC_JOBS:-8}"

printf '\n==> Initializing Android GKI 5.15 workspace: %s\n' "$GKI_DIR"
mkdir -p "$GKI_DIR"
cd "$GKI_DIR"
repo init -u "$KERNEL_MANIFEST" -b "$KERNEL_REVISION"

printf '\n==> Syncing GKI 5.15 kernel workspace\n'
repo sync -c --no-tags --no-clone-bundle -j"${SYNC_JOBS:-8}"

cat <<'EOF'

Bootstrap complete.

Workspaces:
  aosp17/   -> Google AOSP 17 + our OP6 trees + isolated Qualcomm bridge
  gki-5.15/ -> Android common 5.15 GKI source/build workspace

Production-base rules:
  - AOSP android-17.0.0_r1 is the only userspace base.
  - Evolution X and Lineage device trees are donor/reference sources only.
  - Never inherit vendor/lineage product configuration in the production product.
  - Do not store AVB/private signing keys in either workspace.
  - Before any GPT experiment, dump and verify all six UFS LUN partition tables.

Useful donor sync examples (optional):
  repo sync reference/evox/frameworks_base
  repo sync reference/lineage/device/oneplus/enchilada
  repo sync reference/kernel/edwin-oneplus-sdm845-4.19

Initial build target:
  aosp_enchilada

The first goal is userspace/hardware bring-up with the known-good 4.19 bridge
kernel. GKI 5.15 is developed separately and replaces the bridge only after
boot/init/adb/display/touch are stable.
EOF
