#!/usr/bin/env bash
set -euo pipefail

AOSP_ROOT="${1:-$PWD}"
PRODUCT_OUT="${2:-$AOSP_ROOT/out/target/product/enchilada}"

FAIL=0
RUNTIME_RE='ro\.lineage\.|org\.lineageos|vendor\.lineage\.|lineage\.hardware\.|lineage-sdk'

red() { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }

printf '==> AOSP root: %s\n' "$AOSP_ROOT"

ACTIVE_FILES=(
  "device/oneplus/enchilada/AndroidProducts.mk"
  "device/oneplus/enchilada/aosp_enchilada.mk"
  "device/oneplus/enchilada/device.mk"
  "device/oneplus/sdm845-common/aosp-common.mk"
  "device/oneplus/sdm845-common/BoardConfigCommon.mk"
  "device/oneplus/sdm845-common/manifest.xml"
  "device/oneplus/sdm845-common/system.prop"
  "device/oneplus/sdm845-common/system_ext.prop"
  "device/oneplus/sdm845-common/product.prop"
  "device/oneplus/sdm845-common/vendor.prop"
)

printf '\n==> Checking product-facing configuration\n'
for rel in "${ACTIVE_FILES[@]}"; do
  f="$AOSP_ROOT/$rel"
  [[ -f "$f" ]] || { yellow "WARN missing: $rel"; continue; }
  if grep -nEI "$RUNTIME_RE" "$f"; then
    red "FAIL runtime Lineage identifier in $rel"
    FAIL=1
  fi
done

printf '\n==> Checking build-enabled Android.bp/Android.mk files\n'
# Donor-only directories intentionally retain historical source. Their build
# entry points are removed on bringup/aosp17 and they are excluded here.
while IFS= read -r -d '' f; do
  case "$f" in
    */overlay-lineage/*|*/livedisplay/*|*/pocketmode/*|*/aidl/livedisplay/*|*/aidl/touch/*|*/dirac_gef/*|*/packages/Doze/*|*/packages/KeyHandler/*)
      continue
      ;;
  esac
  if grep -nEI "$RUNTIME_RE" "$f"; then
    red "FAIL build-enabled Lineage identifier in ${f#$AOSP_ROOT/}"
    FAIL=1
  fi
done < <(find \
  "$AOSP_ROOT/device/oneplus/enchilada" \
  "$AOSP_ROOT/device/oneplus/sdm845-common" \
  "$AOSP_ROOT/hardware/oneplus" \
  -type f \( -name Android.bp -o -name Android.mk \) -print0 2>/dev/null)

printf '\n==> Informational donor/source scan\n'
yellow 'The following matches are allowed only when they are not build-enabled:'
grep -RInEI \
  --exclude='Android.bp' --exclude='Android.mk' --exclude='BRINGUP.md' \
  --exclude-dir='.git' \
  "$RUNTIME_RE" \
  "$AOSP_ROOT/device/oneplus/enchilada" \
  "$AOSP_ROOT/device/oneplus/sdm845-common" \
  "$AOSP_ROOT/hardware/oneplus" 2>/dev/null || true

if [[ -d "$PRODUCT_OUT" ]]; then
  printf '\n==> Strict runtime-output scan: %s\n' "$PRODUCT_OUT"

  if find "$PRODUCT_OUT" -type f \
      \( -name '*.prop' -o -name '*.xml' -o -name '*.rc' -o -name '*.conf' -o -name '*.txt' -o -name '*.json' \) \
      -print0 | xargs -0 -r grep -nEI "$RUNTIME_RE"; then
    red 'FAIL Lineage runtime identity found in built product text files'
    FAIL=1
  fi

  if find "$PRODUCT_OUT" -type f -o -type l | grep -Ei '/[^/]*(lineage|org\.lineageos|vendor\.lineage)[^/]*$'; then
    red 'FAIL Lineage-named files found in built product'
    FAIL=1
  fi
else
  yellow "WARN product output not present yet; runtime scan skipped"
fi

printf '\n'
if [[ "$FAIL" -ne 0 ]]; then
  red 'IDENTITY AUDIT FAILED'
  exit 1
fi

green 'IDENTITY AUDIT PASSED'
