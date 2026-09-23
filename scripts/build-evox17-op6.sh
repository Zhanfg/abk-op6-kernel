#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${1:-$HOME/android/op6-rom/evox17}"
VARIANT="${BUILD_VARIANT:-userdebug}"
TARGET="lineage_enchilada-cp2a-${VARIANT}"
PRODUCT_OUT="$WORKSPACE/out/target/product/enchilada"
LOG_DIR="${LOG_DIR:-$WORKSPACE/build-logs}"
STAMP="$(date -u +%Y%m%d-%H%M%S)"

case "$VARIANT" in
  user|userdebug) ;;
  *)
    echo "ERROR: BUILD_VARIANT must be user or userdebug, got: $VARIANT" >&2
    exit 2
    ;;
esac

test -d "$WORKSPACE/.repo" || {
  echo "ERROR: not an initialized repo workspace: $WORKSPACE" >&2
  echo "Run scripts/bootstrap-evox17-op6.sh first." >&2
  exit 2
}

cd "$WORKSPACE"
test -f build/envsetup.sh
test -f device/oneplus/enchilada/AndroidProducts.mk
test -f device/oneplus/enchilada/lineage_enchilada.mk
test -f kernel/oneplus/sdm845/Makefile

mkdir -p "$LOG_DIR"

echo "==> Recording pinned source manifest"
repo manifest -r -o "$LOG_DIR/manifest-$STAMP.xml"

echo "==> Build target: $TARGET"
# shellcheck disable=SC1091
source build/envsetup.sh
lunch "$TARGET"

echo "==> Building Evolution X Android 17 for enchilada"
set +e
m evolution -j"${BUILD_JOBS:-$(nproc --all)}" 2>&1 | tee "$LOG_DIR/evox17-$STAMP.log"
rc=${PIPESTATUS[0]}
set -e

if [ "$rc" -ne 0 ]; then
  echo "ERROR: ROM build failed (exit $rc)." >&2
  echo "Log: $LOG_DIR/evox17-$STAMP.log" >&2
  exit "$rc"
fi

test -d "$PRODUCT_OUT" || {
  echo "ERROR: build completed but PRODUCT_OUT is missing: $PRODUCT_OUT" >&2
  exit 3
}

mapfile -t IMAGES < <(
  find "$PRODUCT_OUT" -maxdepth 1 -type f \
    \( -name 'boot.img' -o -name 'dtbo.img' -o -name 'vbmeta.img' -o -name 'vendor.img' -o -name 'system.img' \) \
    -print | sort
)

mapfile -t PACKAGES < <(
  find "$PRODUCT_OUT" -maxdepth 1 -type f \
    \( -name '*.zip' -o -name '*target_files*.zip' \) \
    -print | sort
)

{
  echo "target=$TARGET"
  echo "workspace=$WORKSPACE"
  echo "product_out=$PRODUCT_OUT"
  echo "build_utc=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo "manifest=$LOG_DIR/manifest-$STAMP.xml"
  echo
  echo "[images]"
  printf '%s\n' "${IMAGES[@]:-}"
  echo
  echo "[packages]"
  printf '%s\n' "${PACKAGES[@]:-}"
} > "$LOG_DIR/build-info-$STAMP.txt"

{
  for f in "${IMAGES[@]}" "${PACKAGES[@]}"; do
    [ -n "$f" ] && [ -f "$f" ] && sha256sum "$f"
  done
} > "$LOG_DIR/sha256-$STAMP.txt"

echo
echo "Build completed."
echo "Product output: $PRODUCT_OUT"
echo "Build info:     $LOG_DIR/build-info-$STAMP.txt"
echo "Checksums:      $LOG_DIR/sha256-$STAMP.txt"
