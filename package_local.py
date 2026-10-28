"""Bundle this editable sample and selected evidence; never include runtime saves."""
from pathlib import Path
import hashlib
import json
import zipfile

ROOT = Path(__file__).resolve().parent
DEST = ROOT.parent / "estacao-raiz-amostra-20261017.zip"
EVIDENCE = {
    ".gdignore", "estacao-raiz-normal.mp4", "estacao-raiz-lento.mp4",
    "estacao-raiz-960.mp4", "progressao-estufa.png", "final-overview.png",
    "final-combat.png", "antes-depois-identidade.png", "motion-review.png",
    "delivery-verification.json", "qa-report.json", "raiz-qa-report.json",
    "raiz-reopen-report.json", "stage-final.json", "normal-launch.log",
    "raiz-reopen-final.log", "extended-qa-final.log", "audio-controls.log",
    "audio-reopen.log",
}

def include(path: Path) -> bool:
    parts = path.relative_to(ROOT).parts
    if any(p in {".godot", "local", "__pycache__"} for p in parts):
        return False
    if path.suffix in {".import", ".pyc", ".b64"}:
        return False
    if parts[0] == "evidence":
        return len(parts) == 2 and parts[1] in EVIDENCE
    return True

if __name__ == "__main__":
    if DEST.exists():
        raise SystemExit(f"Refusing to replace existing bundle: {DEST}")
    sources = sorted(p for p in ROOT.rglob("*") if p.is_file() and include(p))
    with zipfile.ZipFile(DEST, "x", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as bundle:
        for path in sources:
            bundle.write(path, "estacao-raiz/" + path.relative_to(ROOT).as_posix())
    with zipfile.ZipFile(DEST) as bundle:
        assert bundle.testzip() is None
        names = bundle.namelist()
        assert "estacao-raiz/project.godot" in names
        assert "estacao-raiz/visual/world.gd" in names
        assert not any("/local/" in name or "/.godot/" in name for name in names)
    receipt = {
        "path": str(DEST), "bytes": DEST.stat().st_size,
        "sha256": hashlib.sha256(DEST.read_bytes()).hexdigest(),
        "files": len(sources), "zip_crc_test_passed": True,
        "runtime_embedded": False, "save_files_included": False,
        "uploaded": False,
    }
    (ROOT / "evidence/package-receipt.json").write_text(json.dumps(receipt, indent=2), encoding="utf-8")
    print(json.dumps(receipt, indent=2))
