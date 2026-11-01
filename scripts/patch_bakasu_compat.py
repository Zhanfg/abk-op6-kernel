#!/usr/bin/env python3
"""Patch pinned BakaSU in a build sandbox for the OP6 compatibility experiment.

Upstream stays pinned and unchanged. All anchors fail closed on API drift.
This is a signature allowlist, NOT proof of userspace protocol compatibility.
"""
from pathlib import Path
import sys


def replace_exact(path: Path, original: str, replacement: str) -> None:
    contents = path.read_text()
    if contents.count(original) != 1:
        raise SystemExit(f"[ERROR] expected one anchor in {path}, got {contents.count(original)}")
    path.write_text(contents.replace(original, replacement))


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("Usage: patch_bakasu_compat.py <kernel-root>")
    root = Path(sys.argv[1]).resolve()
    ksu = root / "BakaSU/kernel"
    signatures = ksu / "manager/manager_sign.h"
    replace_exact(
        signatures,
        "// KOWX712/KernelSU\n",
        '// KernelSU Next: default official upstream manager certificate.\n'
        '#define EXPECTED_SIZE_NEXT 0x3e6\n'
        '#define EXPECTED_HASH_NEXT "79e590113c4c4c0c222978e413a5faa801666957b1212a328e46c00c69821bf7"\n\n'
        '// SukiSU Ultra: default official upstream manager certificate.\n'
        '#define EXPECTED_SIZE_SUKISU 0x35c\n'
        '#define EXPECTED_HASH_SUKISU "947ae944f3de4ed4c21a7e4f7953ecf351bfa2b36239da37a34111ad29993eef"\n\n'
        "// KOWX712/KernelSU\n",
    )
    apk = ksu / "manager/apk_sign.c"
    replace_exact(
        apk,
        '    { EXPECTED_SIZE_KOWX712, EXPECTED_HASH_KOWX712 }, // KOWX712/KernelSU\n',
        '    { EXPECTED_SIZE_NEXT, EXPECTED_HASH_NEXT }, // KernelSU Next\n'
        '    { EXPECTED_SIZE_SUKISU, EXPECTED_HASH_SUKISU }, // SukiSU Ultra\n',
    )
    # Original function fails to select a surviving manager after removing
    # the active one, potentially leaving a stale active appid.
    manager = ksu / "manager/manager.c"
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
    struct ksu_manager_node *pos, *tmp;
    struct ksu_manager_node *removed = NULL;
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
    replace_exact(manager, old, new)
    # This toolkit exposes state-changing commands. Only processes already
    # possessing CAP_SYS_ADMIN may invoke it; no arbitrary UID enrollment.
    disp = ksu / "supercall/dispatch.c"
    replace_exact(
        disp,
        "#ifdef CONFIG_KSU_TOOLKIT_SUPPORT\nint ksu_try_handle_toolkit_cmd(int magic2, unsigned int cmd, void __user **arg)\n{\n",
        "#ifdef CONFIG_KSU_TOOLKIT_SUPPORT\n"
        "int ksu_try_handle_toolkit_cmd(int magic2, unsigned int cmd, void __user **arg)\n"
        "{\n"
        "    /* Experimental compatibility mode: never trust unprivileged reboot callers. */\n"
        "    if (!capable(CAP_SYS_ADMIN))\n"
        "        return 0;\n",
    )
    print("[OK] BakaSU Next/SukiSU certificate slots, manager removal fix and Toolkit CAP_SYS_ADMIN gate applied")


if __name__ == "__main__":
    main()
