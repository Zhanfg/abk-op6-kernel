#!/usr/bin/env bash
# Verify compiled BakaSU Manual Hook features without SuSFS.
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <kernel-build-root>" >&2
  exit 64
fi

kernel_root="$(realpath "$1")"
config="$kernel_root/out/.config"
module_dir="$kernel_root/out/drivers/kernelsu"
source_dir="$kernel_root/BakaSU"

fail() { echo "[ERROR] BakaSU feature check: $*" >&2; exit 1; }
[[ -s "$config" ]] || fail "final kernel .config missing"
[[ -s "$source_dir/uapi/supercall.h" ]] || fail "BakaSU UAPI missing"
[[ -L "$source_dir/kernel/uapi" ]] || fail "BakaSU kernel UAPI symlink missing"
[[ "$(realpath "$source_dir/kernel/uapi")" == "$(realpath "$source_dir/uapi")" ]] || fail "UAPI points at wrong version"

grep -Fqx "CONFIG_KSU=y" "$config" || fail "KernelSU not effective"
grep -Fqx "CONFIG_KSU_MANUAL_HOOK=y" "$config" || fail "Manual Hook not effective"
if grep -Eq '^CONFIG_KSU_SUSFS([_A-Z0-9]*)=y$' "$config"; then
  fail "SuSFS must be disabled in the BakaSU baseline"
fi
[[ ! -s "$kernel_root/out/fs/susfs.o" ]] || fail "SuSFS object was unexpectedly compiled"
grep -Fqx "CONFIG_KSU_MULTI_MANAGER_SUPPORT=y" "$config" || fail "multi-manager not effective"
! grep -Fqx "CONFIG_KSU_DISABLE_MANAGER=y" "$config" || fail "manager integration disabled"
[[ -s "$module_dir/feature/dynamic_manager.o" ]] || fail "dynamic manager object missing"
[[ -s "$module_dir/manager/throne_tracker.o" ]] || fail "manager tracker object missing"
[[ -s "$module_dir/built-in.a" ]] || fail "BakaSU built-in archive missing"
command -v llvm-nm >/dev/null || fail "llvm-nm not installed"

symbols="$(mktemp)"
trap 'rm -f "$symbols"' EXIT
llvm-nm --defined-only "$module_dir/built-in.a" > "$symbols" || fail "cannot read archive symbols"
grep -Eq '[[:space:]]ksu_handle_dynamic_managergrep -Fq 'DYNAMIC_MANAGER_OP_SET' "$source_dir/uapi/supercall.h" || fail "dynamic-manager UAPI missing"

if [[ "${MODE:-}" == CompatExp ]]; then
  grep -Fqx 'CONFIG_WIREGUARD=y' "$config" || fail "WireGuard not built in"
  grep -Fqx 'CONFIG_KSU_TOOLKIT_SUPPORT=y' "$config" || fail "Toolkit not enabled"
  test -s "$kernel_root/out/drivers/net/wireguard/main.o" || fail "WireGuard main object absent"
  for n in EXPECTED_HASH_NEXT EXPECTED_HASH_SUKISU; do
    grep -Fq "$n" "$source_dir/kernel/manager/manager_sign.h" || fail "missing manager signature $n"
  done
  grep -Fq 'if (!capable(CAP_SYS_ADMIN))' "$source_dir/kernel/supercall/dispatch.c" || fail "Toolkit privilege gate missing"
  echo "[OK] EXP manager allowlist, guarded Toolkit and WireGuard object compiled"
fi

echo "[OK] BakaSU Manual Hook, no SuSFS, multi-manager and dynamic-manager verified"
echo "[INFO] Kernel-side checks only; boot/root/manager persistence require device testing"
 "$symbols" || fail "dynamic manager implementation missing in archive"
# In particular, catch a BakaSU object archive that compiled but did not
# include its lifecycle, fd-install/reboot transport or manager auth code.
# These checks cannot prove that initcalls or APK authentication run on-device.
for ksu_symbol in kernelsu_init ksu_handle_sys_reboot ksu_install_fd ksu_is_manager_appid; do
  grep -Eq "[[:space:]]${ksu_symbol}$" "$symbols" || fail "BakaSU runtime entry point missing: ${ksu_symbol}"
done
grep -Fq 'DYNAMIC_MANAGER_OP_SET' "$source_dir/uapi/supercall.h" || fail "dynamic-manager UAPI missing"

if [[ "${MODE:-}" == CompatExp ]]; then
  grep -Fqx 'CONFIG_WIREGUARD=y' "$config" || fail "WireGuard not built in"
  grep -Fqx 'CONFIG_KSU_TOOLKIT_SUPPORT=y' "$config" || fail "Toolkit not enabled"
  test -s "$kernel_root/out/drivers/net/wireguard/main.o" || fail "WireGuard main object absent"
  for n in EXPECTED_HASH_NEXT EXPECTED_HASH_SUKISU; do
    grep -Fq "$n" "$source_dir/kernel/manager/manager_sign.h" || fail "missing manager signature $n"
  done
  grep -Fq 'if (!capable(CAP_SYS_ADMIN))' "$source_dir/kernel/supercall/dispatch.c" || fail "Toolkit privilege gate missing"
  echo "[OK] EXP manager allowlist, guarded Toolkit and WireGuard object compiled"
fi

echo "[OK] BakaSU Manual Hook, no SuSFS, multi-manager and dynamic-manager verified"
echo "[INFO] Kernel-side checks only; boot/root/manager persistence require device testing"
