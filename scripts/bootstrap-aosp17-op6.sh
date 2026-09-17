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

printf '\n==> Initializing AOSP 17 workspace: %s\n' "$AOSP_DIR"
mkdir -p "$AOSP_DIR"
cd "$AOSP_DIR"
repo init -u "$AOSP_MANIFEST" -b "$AOSP_REVISION"
mkdir -p .repo/local_manifests
cp "$CONTROL_REPO/manifests/op6-reference.xml" .repo/local_manifests/op6-reference.xml

printf '\n==> Syncing AOSP + read-only OP6 references\n'
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
  aosp17/   -> AOSP Android 17 plus reference-only OP6 sources
  gki-5.15/ -> Android common 5.15 GKI source/build workspace

Important:
  - Do not copy Lineage trees directly into active build paths.
  - Do not add Evolution X as a manifest base.
  - Do not store AVB/private signing keys in either workspace.
  - Before any GPT experiment, dump and verify the six UFS LUN partition tables.

Next bring-up step:
  create clean device/oneplus/{sdm845-common,enchilada} trees from AOSP,
  porting only audited hardware enablement from reference/.
EOF
