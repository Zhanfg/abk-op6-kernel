#!/usr/bin/env python3
"""Adapt legacy OnePlus 6 SuSFS 2.1.0 thread-flag helpers to pinned BakaSU.

Uses existing upstream SuSFS definitions (TIF 34 and 35), without changing
device kernel sources or weakening the BakaSU call sites. Fails closed if
the input header no longer matches the pinned kernel baseline.
"""
import pathlib
import sys

def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: patch_bakasu_susfs_legacy.py <kernel-root>")
    root = pathlib.Path(sys.argv[1]).resolve()
    header = root / "include/linux/susfs_def.h"
    flags = root / "arch/arm64/include/asm/thread_info.h"
    if not header.is_file() or not flags.is_file():
        raise SystemExit("SuSFS header or ARM64 flags header missing")
    text = header.read_text()
    flagtext = flags.read_text()

    if "#define TIF_PROC_UMOUNTED 33\n" not in text:
        raise SystemExit("Legacy SuSFS flag anchor absent; refuse unverified patch")
    for flag in ("TIF_PROC_NO_SU", "TIF_PROC_UMOUNTED_FOR_ZYGOTE_NEXT"):
        if flag in text or flag in flagtext:
            raise SystemExit(f"{flag} already exists; examine manually before building")

    flags_patch = (
        "#define TIF_PROC_UMOUNTED 33\n"
        "/* Match the current SuSFS 2.x API used by BakaSU inline hooks. */\n"
        "#define TIF_PROC_NO_SU 34\n"
        "#define TIF_PROC_UMOUNTED_FOR_ZYGOTE_NEXT 35\n"
    )
    text = text.replace("#define TIF_PROC_UMOUNTED 33\n", flags_patch, 1)

    anchor = "#define SUSFS_IS_INODE_SUS_MAP(inode)"
    if text.count(anchor) != 1:
        raise SystemExit("SuSFS helper anchor missing or ambiguous")

    helpers = """/*
 * Port of upstream SuSFS thread-local flag helpers; these must not be
 * replaced with no-op stubs. Linux 4.19 arm64 has free TIF bits 34/35.
 */
static inline bool susfs_is_current_proc_no_su(void)
{
    return likely(test_thread_flag(TIF_PROC_NO_SU));
}

static inline void susfs_set_current_proc_no_su(void)
{
    set_thread_flag(TIF_PROC_NO_SU);
}

static inline void susfs_clear_current_proc_no_su(void)
{
    clear_thread_flag(TIF_PROC_NO_SU);
}

static inline bool susfs_is_current_proc_umounted_for_zygote_next(void)
{
    return likely(test_thread_flag(TIF_PROC_UMOUNTED_FOR_ZYGOTE_NEXT));
}

static inline void susfs_set_current_proc_umounted_for_zygote_next(void)
{
    set_thread_flag(TIF_PROC_UMOUNTED_FOR_ZYGOTE_NEXT);
}

static inline void susfs_clear_current_proc_umounted_for_zygote_next(void)
{
    clear_thread_flag(TIF_PROC_UMOUNTED_FOR_ZYGOTE_NEXT);
}

"""
    text = text.replace(anchor, helpers + anchor, 1)
    header.write_text(text)
    if text.count("static inline void susfs_set_current_proc_no_su") != 1:
        raise SystemExit("Post-patch check failed")
    print("[OK] SuSFS 2.1.0 compatibility: no-su + zygote_next TIF helpers added")
    print("[INFO] Does not assert full modern SuSFS 2.x mount semantics; runtime testing remains required")

if __name__ == "__main__":
    main()
