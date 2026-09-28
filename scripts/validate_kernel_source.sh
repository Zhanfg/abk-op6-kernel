#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <kernel-root> <defconfig-path>" >&2
}

fail() {
  echo "[ERROR] $*" >&2
  exit 1
}

[[ $# -eq 2 ]] || { usage; exit 64; }

kernel_root="$(realpath "$1")"
defconfig_rel="$2"

[[ "$defconfig_rel" != /* ]] || fail "defconfig path must be relative"
[[ "$defconfig_rel" != *".."* ]] || fail "defconfig path must not contain '..'"
[[ "$defconfig_rel" == arch/arm64/configs/*_defconfig ]] ||   fail "defconfig must be under arch/arm64/configs/ and end with _defconfig"

makefile="$kernel_root/Makefile"
defconfig="$kernel_root/$defconfig_rel"
drivers_makefile="$kernel_root/drivers/Makefile"
drivers_kconfig="$kernel_root/drivers/Kconfig"

[[ -f "$makefile" ]] || fail "kernel Makefile is missing"
[[ -f "$defconfig" ]] || fail "defconfig is missing: $defconfig_rel"
[[ -f "$drivers_makefile" ]] || fail "drivers/Makefile is missing"
[[ -f "$drivers_kconfig" ]] || fail "drivers/Kconfig is missing"
[[ -f "$kernel_root/drivers/kernelsu/Kconfig" ]] || fail "drivers/kernelsu/Kconfig is missing"
[[ -f "$kernel_root/drivers/kernelsu/Kbuild" ]] || fail "drivers/kernelsu/Kbuild is missing"
[[ -f "$kernel_root/fs/susfs.c" ]] || fail "fs/susfs.c is missing"
[[ -f "$kernel_root/include/linux/susfs.h" ]] || fail "include/linux/susfs.h is missing"

grep -Eq '^VERSION[[:space:]]*=[[:space:]]*4([[:space:]]|$)' "$makefile" ||   fail "ABK OnePlus 6 builder requires Linux 4.x"
grep -Eq '^PATCHLEVEL[[:space:]]*=[[:space:]]*19([[:space:]]|$)' "$makefile" ||   fail "ABK OnePlus 6 builder requires Linux 4.19"

grep -Fqx 'obj-$(CONFIG_KSU) += kernelsu/' "$drivers_makefile" ||   fail "drivers/Makefile does not build drivers/kernelsu"
grep -Fqx 'source "drivers/kernelsu/Kconfig"' "$drivers_kconfig" ||   fail "drivers/Kconfig does not source drivers/kernelsu/Kconfig"

required_y_symbols=(
  KPROBES
  KRETPROBES
  KSU
  KSU_MANUAL_HOOK
  KSU_SUSFS
  KSU_SUSFS_HAS_MAGIC_MOUNT
  KSU_SUSFS_SUS_PATH
  KSU_SUSFS_SUS_KSTAT
  KSU_SUSFS_SUS_MOUNT
  KSU_SUSFS_OPEN_REDIRECT
)

for symbol in "${required_y_symbols[@]}"; do
  grep -Fqx "CONFIG_${symbol}=y" "$defconfig" ||     fail "required config is not enabled: CONFIG_${symbol}=y"
done

echo "[OK] Linux 4.19 OnePlus 6 source contract matches ABK expectations"
