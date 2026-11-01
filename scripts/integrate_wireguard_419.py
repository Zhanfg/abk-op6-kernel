#!/usr/bin/env python3
"""Enable the WireGuard driver already integrated in OP6 Linux 4.19.

The pinned OnePlus 6 kernel source already contains drivers/net/wireguard,
with Kconfig/Kbuild and the required crypto dependencies. Avoid replacing
its vendor backport with a second incompatible copy.
"""
from pathlib import Path
import sys


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("Usage: integrate_wireguard_419.py <kernel-root>")
    root = Path(sys.argv[1]).resolve()
    netcfg = root / "drivers/net/Kconfig"
    netmake = root / "drivers/net/Makefile"
    wg = root / "drivers/net/wireguard"
    cfg = root / "arch/arm64/configs/vendor/enchilada_defconfig"
    for required in (wg / "Makefile", wg / "main.c", wg / "noise.c", netcfg, netmake, cfg):
        if not required.is_file():
            raise SystemExit(f"[ERROR] existing WireGuard source missing: {required}")
    if 'config WIREGUARD\n' not in netcfg.read_text():
        raise SystemExit("[ERROR] WireGuard Kconfig not registered")
    if 'obj-$(CONFIG_WIREGUARD) += wireguard/' not in netmake.read_text():
        raise SystemExit("[ERROR] WireGuard Kbuild edge missing")
    text = cfg.read_text()
    if "CONFIG_WIREGUARD=y" not in text:
        text += "\n# OP6 experiment: activate existing built-in WireGuard\n"
        text += "CONFIG_WIREGUARD=y\n"
        text += "# CONFIG_WIREGUARD_DEBUG is not set\n"
        cfg.write_text(text)
    print("[OK] OP6 in-tree WireGuard enabled without replacing vendor source")


if __name__ == "__main__":
    main()
