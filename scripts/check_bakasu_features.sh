#!/usr/bin/env bash
# Validate that BakaSU's optional manager support is *actually* compiled.
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
grep -Fqx "CONFIG_KSU=y" "$config" || fail "CONFIG_KSU=y not effective"
grep -Fqx "CONFIG_KSU_SUSFS=y" "$config" || fail "SuSFS inline hook not effective on Linux 4.19"
grep -Fqx "CONFIG_KSU_MULTI_MANAGER_SUPPORT=y" "$config" || fail "multi-manager support not effective"
! grep -Fqx "CONFIG_KSU_DISABLE_MANAGER=y" "$config" || fail "manager integration disabled"
[[ -s "$module_dir/feature/dynamic_manager.o" ]] || fail "dynamic manager object wasn't compiled"
[[ -s "$module_dir/manager/throne_tracker.o" ]] || fail "manager tracker object wasn't compiled"
# Linux 4.19 Kbuild archives built-in objects directly; not every build
# emits the intermediate kernelsu.o composite. Verify the produced archive
# and the actual dynamic-manager symbol instead of requiring that filename.
[[ -s "$module_dir/built-in.a" ]] || fail "BakaSU built-in archive missing"
command -v llvm-nm >/dev/null || fail "llvm-nm not installed"
symbol_index="$(mktemp)"
trap 'rm -f "$symbol_index"' EXIT
llvm-nm --defined-only "$module_dir/built-in.a" > "$symbol_index" || fail "cannot read BakaSU archive symbols"
grep -Eq '[[:space:]]ksu_handle_dynamic_manager
grep -Fq 'DYNAMIC_MANAGER_OP_SET' "$source_dir/uapi/supercall.h" || fail "dynamic-manager UAPI missing"

echo "[OK] BakaSU Linux 4.19 SuSFS inline hook, multi-manager and dynamic-manager objects verified"
echo "[INFO] Kernel-side verification only; dynamic manager persistent settings need matching BakaSU ksud/Manager"
 "$symbol_index" || fail "dynamic-manager symbol missing in built-in archive"
grep -Fq 'DYNAMIC_MANAGER_OP_SET' "$source_dir/uapi/supercall.h" || fail "dynamic-manager UAPI missing"

echo "[OK] BakaSU Linux 4.19 SuSFS inline hook, multi-manager and dynamic-manager objects verified"
echo "[INFO] Kernel-side verification only; dynamic manager persistent settings need matching BakaSU ksud/Manager"
