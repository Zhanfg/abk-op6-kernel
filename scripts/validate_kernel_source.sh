#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[ERROR] $*" >&2; exit 1; }

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 <kernel-root> <defconfig-path> [BakaSU|ReSukiSU]" >&2
  exit 64
fi

kernel_root="$(realpath "$1")"
defconfig_rel="$2"
engine="${3:-ReSukiSU}"
case "$engine" in BakaSU|ReSukiSU) ;; *) fail "unknown root engine: $engine";; esac

[[ "$defconfig_rel" != /* && "$defconfig_rel" != *".."* ]] || fail "invalid defconfig relative path"
[[ "$defconfig_rel" == arch/arm64/configs/*_defconfig ]] || fail "unexpected defconfig location"

makefile="$kernel_root/Makefile"
defconfig="$kernel_root/$defconfig_rel"
drivers_makefile="$kernel_root/drivers/Makefile"
drivers_kconfig="$kernel_root/drivers/Kconfig"

for f in "$makefile" "$defconfig" "$drivers_makefile" "$drivers_kconfig"          "$kernel_root/drivers/kernelsu/Kconfig" "$kernel_root/drivers/kernelsu/Kbuild"; do
  [[ -f "$f" ]] || fail "required source file missing: $f"
done

grep -Eq '^VERSION[[:space:]]*=[[:space:]]*4([[:space:]]|$)' "$makefile" || fail "Linux 4.x required"
grep -Eq '^PATCHLEVEL[[:space:]]*=[[:space:]]*19([[:space:]]|$)' "$makefile" || fail "Linux 4.19 required"
grep -Fqx 'obj-$(CONFIG_KSU) += kernelsu/' "$drivers_makefile" || fail "drivers/Makefile lacks KSU build edge"
grep -Fqx 'source "drivers/kernelsu/Kconfig"' "$drivers_kconfig" || fail "drivers/Kconfig lacks KSU Kconfig"

required_y_symbols=(KPROBES KRETPROBES KSU KSU_MANUAL_HOOK)
if [[ "$engine" == ReSukiSU ]]; then
  required_y_symbols+=(KSU_SUSFS KSU_SUSFS_HAS_MAGIC_MOUNT KSU_SUSFS_SUS_PATH KSU_SUSFS_SUS_KSTAT KSU_SUSFS_SUS_MOUNT KSU_SUSFS_OPEN_REDIRECT)
  [[ -f "$kernel_root/fs/susfs.c" ]] || fail "legacy SuSFS source missing"
  [[ -f "$kernel_root/include/linux/susfs.h" ]] || fail "legacy SuSFS header missing"
else
  if grep -Eq '^CONFIG_KSU_SUSFS([_A-Z0-9]*)=y$' "$defconfig"; then
    fail "BakaSU baseline must not enable any SuSFS option"
  fi
fi

for symbol in "${required_y_symbols[@]}"; do
  grep -Fqx "CONFIG_${symbol}=y" "$defconfig" || fail "required config not enabled: CONFIG_${symbol}=y"
done

echo "[OK] OnePlus 6 Linux 4.19 source contract for $engine"
