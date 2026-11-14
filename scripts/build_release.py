#!/usr/bin/env python3
"""Build one installable ZIP per addon in a Git commit."""

import argparse
import re
import subprocess
from pathlib import Path, PurePosixPath
from tempfile import TemporaryDirectory
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo


ROOT = Path(__file__).resolve().parents[1]


def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args])


def addon_files(commit):
    addons = {}
    entries = git("ls-tree", "-rz", commit, "--", "addons/")
    for entry in entries.split(b"\0")[:-1]:
        metadata, raw_path = entry.split(b"\t", 1)
        mode, _, blob = metadata.decode("ascii").split()
        path = PurePosixPath(raw_path.decode("utf-8"))
        if len(path.parts) < 3:
            raise ValueError(f"Expected an addon directory for {path}")
        name = path.parts[1]
        if not re.fullmatch(r"[A-Za-z0-9_][A-Za-z0-9_-]*", name):
            raise ValueError(f"Invalid addon folder name: {name}")
        if mode not in {"100644", "100755"}:
            raise ValueError(f"Expected a regular file at {path}")
        member = path.relative_to("addons").as_posix()
        addons.setdefault(name, {})[member] = blob

    if not addons:
        raise ValueError("No addons found in the selected commit")
    if len({name.lower() for name in addons}) != len(addons):
        raise ValueError("Addon folder names must be unique on case-insensitive file systems")
    for name, files in addons.items():
        if f"{name}/{name}.toc" not in files:
            raise ValueError(f"Missing addons/{name}/{name}.toc")
    return addons


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ref", default="HEAD", help="Git commit or tag to package")
    parser.add_argument("--output-dir", type=Path, default=ROOT / "dist")
    args = parser.parse_args()

    try:
        commit = git("rev-parse", "--verify", "--end-of-options", f"{args.ref}^{{commit}}")
        addons = addon_files(commit.decode("ascii").strip())
        args.output_dir.mkdir(parents=True, exist_ok=True)
        with TemporaryDirectory(dir=args.output_dir) as staging:
            archives = []
            for name, files in sorted(addons.items()):
                archive = Path(staging) / f"{name}.zip"
                with ZipFile(archive, "w") as output:
                    for member, blob in sorted(files.items()):
                        info = ZipInfo(member)
                        info.create_system = 3
                        info.external_attr = 0o100644 << 16
                        output.writestr(info, git("cat-file", "blob", blob), ZIP_DEFLATED)
                archives.append(archive)
            for archive in archives:
                print(archive.replace(args.output_dir / archive.name).resolve())
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Build failed: {error}\n")


if __name__ == "__main__":
    main()
