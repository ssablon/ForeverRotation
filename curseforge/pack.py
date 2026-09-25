# -*- coding: utf-8 -*-
"""Build the CurseForge zip: one root folder named WoWForeverRot, no .git."""
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def version():
    for line in (ROOT / "VERSION.txt").read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            return line
    raise SystemExit("VERSION.txt missing version")


OUT = Path(r"F:\Github\addons\wow") / f"WoWForeverRot-{version()}.zip"

SKIP_DIRS = {".git", ".cursor", "curseforge", "__pycache__", ".idea", ".vscode"}
SKIP_FILES = {"AGENTS.md", "LISEZMOI.txt"}
SKIP_SUFFIX = {".pyc", ".bak", ".tmp", ".log"}


def keep(path: Path) -> bool:
    rel = path.relative_to(ROOT)
    if any(part in SKIP_DIRS for part in rel.parts):
        return False
    if path.name in SKIP_FILES:
        return False
    if path.suffix.lower() in SKIP_SUFFIX:
        return False
    if path.name == "ARCHITECTURE.md" or path.name == "FOREVER_SPELLBOOK.md":
        return False
    return True


def main():
    files = [p for p in ROOT.rglob("*") if p.is_file() and keep(p)]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    if OUT.exists():
        OUT.unlink()
    with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as zf:
        for path in files:
            zf.write(path, Path("WoWForeverRot") / path.relative_to(ROOT))
    print("wrote", OUT, "files", len(files), "bytes", OUT.stat().st_size)


if __name__ == "__main__":
    main()
