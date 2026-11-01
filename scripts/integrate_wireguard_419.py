#!/usr/bin/env python3
"""Integrate a pinned WireGuard 3.10–5.5 compat tree into Linux 4.19.

Run after cloning WireGuard/wireguard-linux-compat into <kernel>/WireGuardCompat.
No kernel source modification is persisted to the source remote.
"""
from pathlib import Path
import shutil
import sys


def edit(path: Path, needle: str, replacement: str) -> None:
    s = path.read_text()
    if s.count(needle) != 1:
        raise SystemExit(f"[ERROR] unexpected {path} anchor count {s.count(needle)}")
    path.write_text(s.replace(needle, replacement))


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("Usage: integrate_wireguard_419.py <kernel-root>")
    root = Path(sys.argv[1]).resolve()
    source = root / "WireGuardCompat/src"
    target = root / "drivers/net/wireguard"
    for rel in ("Kconfig", "Kbuild", "main.c", "compat/Kbuild.include"):
        if not (source / rel).is_file():
            raise SystemExit(f"[ERROR] WireGuard compat missing {rel}")
    if target.exists():
        raise SystemExit("[ERROR] target wireguard tree already present")
    shutil.copytree(source, target, ignore=shutil.ignore_patterns(".git", "tests", "selftest"))
    edit(
        root / "drivers/net/Kconfig",
        "endif # NETDEVICES\n",
        'source "drivers/net/wireguard/Kconfig"\n\nendif # NETDEVICES\n',
    )
    with (root / "drivers/net/Makefile").open("a") as f:
        f.write("\n# OP6: pinned WireGuard Linux 4.19 compatibility backport\n")
        f.write("obj-$(CONFIG_WIREGUARD) += wireguard/\n")
    cfg = root / "arch/arm64/configs/vendor/enchilada_defconfig"
    with cfg.open("a") as f:
        f.write("\n# OP6 compatibility experiment: native WireGuard transport\n")
        f.write("CONFIG_WIREGUARD=y\n")
        f.write("# CONFIG_WIREGUARD_DEBUG is not set\n")
    print("[OK] WireGuard 4.19 compat driver integrated and enabled (built-in)")


if __name__ == "__main__":
    main()
