#!/usr/bin/env bash
set -euo pipefail

KERNEL_ROOT="${1:?usage: build-gki-5.15-resukisu-susfs.sh <android-kernel-workspace>}"
COMMON="$KERNEL_ROOT/common"
RESUKISU_REPO="https://github.com/ReSukiSU/ReSukiSU.git"
SUSFS_REPO="https://gitlab.com/simonpunk/susfs4ksu.git"
SUSFS_BRANCH="${SUSFS_BRANCH:-gki-android14-5.15}"

test -d "$COMMON" || { echo "ERROR: missing $COMMON" >&2; exit 1; }
cd "$KERNEL_ROOT"

RESUKISU_SHA="$(git ls-remote "$RESUKISU_REPO" refs/heads/main | awk '{print $1}')"
SUSFS_SHA="$(git ls-remote "$SUSFS_REPO" "refs/heads/$SUSFS_BRANCH" | awk '{print $1}')"
[[ "$RESUKISU_SHA" =~ ^[0-9a-f]{40}$ ]] || { echo "ERROR: failed to resolve ReSukiSU main" >&2; exit 1; }
[[ "$SUSFS_SHA" =~ ^[0-9a-f]{40}$ ]] || { echo "ERROR: failed to resolve SUSFS $SUSFS_BRANCH" >&2; exit 1; }

echo "ReSukiSU: $RESUKISU_SHA"
echo "SUSFS:     $SUSFS_SHA ($SUSFS_BRANCH)"

curl --fail --location --retry 3   "https://raw.githubusercontent.com/ReSukiSU/ReSukiSU/$RESUKISU_SHA/kernel/setup.sh"   -o /tmp/resukisu-setup.sh
chmod +x /tmp/resukisu-setup.sh
/tmp/resukisu-setup.sh "$RESUKISU_SHA"

grep -q 'config KSU_SUSFS' "$KERNEL_ROOT/KernelSU/kernel/Kconfig" || {
  echo "ERROR: selected ReSukiSU does not expose native CONFIG_KSU_SUSFS" >&2
  exit 1
}

rm -rf "$KERNEL_ROOT/susfs4ksu"
git clone --depth=1 --branch "$SUSFS_BRANCH" "$SUSFS_REPO" "$KERNEL_ROOT/susfs4ksu"
if [ "$(git -C "$KERNEL_ROOT/susfs4ksu" rev-parse HEAD)" != "$SUSFS_SHA" ]; then
  git -C "$KERNEL_ROOT/susfs4ksu" fetch --depth=1 origin "$SUSFS_SHA"
  git -C "$KERNEL_ROOT/susfs4ksu" checkout --detach "$SUSFS_SHA"
fi

SUSFS="$KERNEL_ROOT/susfs4ksu"
PATCH="$SUSFS/kernel_patches/50_add_susfs_in_$SUSFS_BRANCH.patch"
if [ ! -f "$PATCH" ]; then
  PATCH="$SUSFS/kernel_patches/50_add_susfs_in_kernel-5.15.patch"
fi
test -f "$PATCH" || {
  echo "ERROR: no SUSFS kernel patch found for $SUSFS_BRANCH" >&2
  find "$SUSFS/kernel_patches" -maxdepth 1 -type f -print >&2 || true
  exit 1
}

cp -f "$SUSFS"/kernel_patches/fs/* "$COMMON/fs/"
cp -f "$SUSFS"/kernel_patches/include/linux/* "$COMMON/include/linux/"

cd "$COMMON"
patch --dry-run --forward -p1 < "$PATCH"
patch --forward -p1 < "$PATCH"

SUSFS_VERSION="$(grep -E '^#define[[:space:]]+SUSFS_VERSION[[:space:]]+' include/linux/susfs.h | awk '{gsub(/"/,"",$3); print $3; exit}')"
test -n "$SUSFS_VERSION" || SUSFS_VERSION="unknown"
echo "SUSFS version detected: $SUSFS_VERSION"

CONFIG="arch/arm64/configs/gki_defconfig"
test -x scripts/config || chmod +x scripts/config
scripts/config --file "$CONFIG" -e KSU
scripts/config --file "$CONFIG" -e KSU_SUSFS
scripts/config --file "$CONFIG" -d KSU_TRACEPOINT_HOOK
scripts/config --file "$CONFIG" -d KSU_MANUAL_HOOK
scripts/config --file "$CONFIG" -e KSU_SUSFS_SUS_PATH
scripts/config --file "$CONFIG" -e KSU_SUSFS_SUS_MOUNT
scripts/config --file "$CONFIG" -e KSU_SUSFS_SUS_KSTAT
scripts/config --file "$CONFIG" -e KSU_SUSFS_SPOOF_UNAME
scripts/config --file "$CONFIG" -e KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG
scripts/config --file "$CONFIG" -e KSU_SUSFS_OPEN_REDIRECT
scripts/config --file "$CONFIG" -e KSU_SUSFS_SUS_MAP
scripts/config --file "$CONFIG" -e KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS

cd "$KERNEL_ROOT"
COMMON_SHA="$(git -C common rev-parse HEAD)"
export BUILD_CONFIG=common/build.config.gki.aarch64
export OUT_DIR="$KERNEL_ROOT/out/kernel"
export DIST_DIR="$KERNEL_ROOT/out/dist"
export KBUILD_BUILD_USER=op6-gki
export KBUILD_BUILD_HOST=github-actions
export LLVM=1
export LLVM_IAS=1
export LTO=thin

build/build.sh

CONFIG_OUT="$(find "$OUT_DIR" -type f -name .config -print -quit)"
test -n "$CONFIG_OUT" && test -s "$CONFIG_OUT"
grep -q '^CONFIG_KSU=y$' "$CONFIG_OUT"
grep -q '^CONFIG_KSU_SUSFS=y$' "$CONFIG_OUT"
! grep -q '^CONFIG_KSU_TRACEPOINT_HOOK=y$' "$CONFIG_OUT"

IMAGE="$(find "$DIST_DIR" -maxdepth 2 -type f -name Image -print -quit)"
test -n "$IMAGE" && test -s "$IMAGE"

cp "$CONFIG_OUT" "$DIST_DIR/gki.config"
{
  echo "project=OnePlus 6 GKI bring-up"
  echo "kernel_manifest_branch=${KERNEL_MANIFEST_BRANCH:-unknown}"
  echo "kernel_common_sha=$COMMON_SHA"
  echo "resukisu_sha=$RESUKISU_SHA"
  echo "susfs_branch=$SUSFS_BRANCH"
  echo "susfs_sha=$SUSFS_SHA"
  echo "susfs_version=$SUSFS_VERSION"
  echo "hook_mode=SUSFS Inline Hook"
  echo "ksu_builtin=true"
  echo "image_sha256=$(sha256sum "$IMAGE" | awk '{print $1}')"
} > "$DIST_DIR/GKI_BUILD_INFO.txt"

echo
echo "Build complete:"
cat "$DIST_DIR/GKI_BUILD_INFO.txt"
