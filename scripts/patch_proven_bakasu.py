#!/usr/bin/env python3
"""Strict 4-manager allowlist patch for the ACTUALLY boot-tested v0.2 BakaSU tree.

Only patch pinned 5b76b884... in build sandbox. No broad auth bypass,
no kernel driver replacement, no unverified full protocol compatibility.
"""
from pathlib import Path
import sys


def replace_once(path: Path, old: str, new: str) -> None:
    data = path.read_text()
    n = data.count(old)
    if n != 1:
        raise SystemExit(f"ABORT: {path} expected 1 original anchor, found {n}")
    path.write_text(data.replace(old, new))


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("Usage: python3 patch_proven_bakasu.py <kernel-tree>")
    base = Path(sys.argv[1]).resolve()
    ksu = base / "KernelSU/kernel"
    if not (ksu / "Kbuild").is_file():
        raise SystemExit("ABORT: verified v0.2 BakaSU source not available")
    sign = ksu / "manager/manager_sign.h"
    replace_once(
        sign,
        "// KOWX712/KernelSU\n",
        '// KernelSU Next default signed release\n'
        '#define EXPECTED_SIZE_NEXT 0x3e6\n'
        '#define EXPECTED_HASH_NEXT "79e590113c4c4c0c222978e413a5faa801666957b1212a328e46c00c69821bf7"\n\n'
        '// SukiSU Ultra default signed release\n'
        '#define EXPECTED_SIZE_SUKISU 0x35c\n'
        '#define EXPECTED_HASH_SUKISU "947ae944f3de4ed4c21a7e4f7953ecf351bfa2b36239da37a34111ad29993eef"\n\n'
        '// KOWX712/KernelSU\n',
    )
    apk = ksu / "manager/apk_sign.c"
    replace_once(
        apk,
        '    { EXPECTED_SIZE_KOWX712, EXPECTED_HASH_KOWX712 }, // KOWX712/KernelSU\n',
        '    { EXPECTED_SIZE_NEXT, EXPECTED_HASH_NEXT }, // KernelSU Next\n'
        '    { EXPECTED_SIZE_SUKISU, EXPECTED_HASH_SUKISU }, // SukiSU Ultra\n',
    )
    # Remove-current-manager fallback must point to one of the still-registered
    # appids. Keep RCU free, which was already present in the tested baseline.
    mgr = ksu / "manager/manager.c"
    old = """void ksu_unregister_manager(u32 uid)
{
    struct ksu_manager_node *node, *pos, *tmp;
    bool mark_another_manager = false;

    if (!ksu_is_manager_uid(uid))
        return;

    u16 appid = uid % PER_USER_RANGE;

    if (ksu_last_manager_appid == appid)
        mark_another_manager = true;

    spin_lock(&ksu_manager_list_write_lock);

    list_for_each_entry_safe (pos, tmp, &ksu_manager_appid_list, list) {
        if (pos->appid == appid) {
            list_del_rcu(&pos->list);
            spin_unlock(&ksu_manager_list_write_lock);
            kfree_rcu(pos, rcu);
            return;
        }

        if (mark_another_manager) {
            ksu_last_manager_appid = appid;
            mark_another_manager = false;
        }
    }

    spin_unlock(&ksu_manager_list_write_lock);

    if (mark_another_manager)
        ksu_last_manager_appid = KSU_INVALID_APPID;
    return;
}
"""
    new = """void ksu_unregister_manager(u32 uid)
{
    struct ksu_manager_node *pos, *tmp, *removed = NULL;
    u16 appid = uid % PER_USER_RANGE;
    u16 fallback = KSU_INVALID_APPID;

    spin_lock(&ksu_manager_list_write_lock);
    list_for_each_entry_safe (pos, tmp, &ksu_manager_appid_list, list) {
        if (pos->appid == appid) {
            list_del_rcu(&pos->list);
            removed = pos;
            continue;
        }
        if (fallback == KSU_INVALID_APPID)
            fallback = pos->appid;
    }
    if (removed && ksu_last_manager_appid == appid)
        ksu_last_manager_appid = fallback;
    spin_unlock(&ksu_manager_list_write_lock);

    if (removed)
        kfree_rcu(removed, rcu);
}
"""
    replace_once(mgr, old, new)
    print("PASS: pinned BakaSU: official+BakaSU+Next+SukiSU certificates; manager fallback repaired")
    print("NOTE: sign allowlist != runtime APK protocol certification")


if __name__ == "__main__":
    main()
