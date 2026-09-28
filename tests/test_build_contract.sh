#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

kernel="$tmp_root/kernel"
defconfig_rel="arch/arm64/configs/vendor/enchilada_defconfig"

mkdir -p   "$kernel/drivers/kernelsu"   "$kernel/arch/arm64/configs/vendor"   "$kernel/fs"   "$kernel/include/linux"

cat > "$kernel/Makefile" <<'EOF'
VERSION = 4
PATCHLEVEL = 19
SUBLEVEL = 325
EOF

cat > "$kernel/drivers/Makefile" <<'EOF'
obj-y += base/
obj-$(CONFIG_KSU) += kernelsu/
EOF

cat > "$kernel/drivers/Kconfig" <<'EOF'
menu "Device Drivers"
source "drivers/kernelsu/Kconfig"
endmenu
EOF

cat > "$kernel/drivers/kernelsu/Kconfig" <<'EOF'
config KSU
  bool "ReSukiSU"
EOF

cat > "$kernel/drivers/kernelsu/Kbuild" <<'EOF'
obj-$(CONFIG_KSU) += kernelsu.o
EOF

: > "$kernel/fs/susfs.c"
: > "$kernel/include/linux/susfs.h"

cat > "$kernel/$defconfig_rel" <<'EOF'
CONFIG_KPROBES=y
CONFIG_KRETPROBES=y
CONFIG_KSU=y
CONFIG_KSU_MANUAL_HOOK=y
CONFIG_KSU_SUSFS=y
CONFIG_KSU_SUSFS_HAS_MAGIC_MOUNT=y
CONFIG_KSU_SUSFS_SUS_PATH=y
CONFIG_KSU_SUSFS_SUS_KSTAT=y
CONFIG_KSU_SUSFS_SUS_MOUNT=y
CONFIG_KSU_SUSFS_OPEN_REDIRECT=y
EOF

validator="$repo_root/scripts/validate_kernel_source.sh"

bash "$validator" "$kernel" "$defconfig_rel"

cp "$kernel/Makefile" "$kernel/Makefile.good"
sed -i 's/PATCHLEVEL = 19/PATCHLEVEL = 9/' "$kernel/Makefile"
if bash "$validator" "$kernel" "$defconfig_rel"; then
  echo "expected Linux 4.9 fixture to be rejected" >&2
  exit 1
fi
mv "$kernel/Makefile.good" "$kernel/Makefile"

cp "$kernel/$defconfig_rel" "$kernel/$defconfig_rel.good"
sed -i '/^CONFIG_KSU_SUSFS=y$/d' "$kernel/$defconfig_rel"
if bash "$validator" "$kernel" "$defconfig_rel"; then
  echo "expected missing CONFIG_KSU_SUSFS=y to be rejected" >&2
  exit 1
fi
mv "$kernel/$defconfig_rel.good" "$kernel/$defconfig_rel"

cp "$kernel/drivers/Makefile" "$kernel/drivers/Makefile.good"
sed -i '/CONFIG_KSU/d' "$kernel/drivers/Makefile"
if bash "$validator" "$kernel" "$defconfig_rel"; then
  echo "expected missing drivers/kernelsu build edge to be rejected" >&2
  exit 1
fi
mv "$kernel/drivers/Makefile.good" "$kernel/drivers/Makefile"

echo "[OK] ABK build-contract tests passed"
