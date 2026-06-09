#!/usr/bin/env python3
"""生成 AnyKernel3 的 anykernel.sh，根据传入的模式名称"""
import sys
import os

def gen_anykernel(mode_name="ABK_OnePlus6"):
    powersave = "PowerSave" in mode_name
    desc = f"ABK OnePlus6 ReSukiSU+SuSFS2.1.00+{'PowerSave(Schedutil+NoBoost+Autosleep)' if powersave else 'Standard'}"
    block = "boot"
    is_slot = "auto"
    ramdisk = "auto"
    patch_vbmeta = "auto"
    cleanups = "1"
    cleanupabort = "0"

    return f"""### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
properties() { '
kernel.string={desc}
do.devicecheck=0
do.modules=0
do.systemless=0
do.cleanups={cleanups}
do.cleanupabort={cleanupabort}
supported.versions=
supported.patchlevels=
'; }

block={block};
is_slot_device={is_slot};
ramdisk_compression={ramdisk};
patch_vbmeta_flag={patch_vbmeta};

. tools/ak3-core.sh;

## AnyKernel boot install
dump_boot;

write_boot;
## end boot install

## dtbo_img flash (OnePlus 6 requires separate dtbo partition)
if [ -f "dtbo.img" ]; then
  block=$(dump_dtbo_partition)
  write_dtbo
fi
"""

if __name__ == "__main__":
    name = sys.argv[1] if len(sys.argv) > 1 else "ABK_OnePlus6_ReSukiSU_Standard"
    out_path = "AnyKernel3/anykernel.sh"
    if len(sys.argv) > 2:
        out_path = sys.argv[2]
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w") as f:
        f.write(gen_anykernel(name))
    print(f"✓ Generated {out_path} ({name})")
