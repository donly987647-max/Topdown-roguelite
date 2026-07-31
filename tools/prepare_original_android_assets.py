from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE_GAME_COMMIT = "c23bdddec9f8b0dfab355faff5d4b212e6755be7"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def git_value(*args: str, fallback: str) -> str:
    try:
        return subprocess.check_output(
            ["git", *args], cwd=ROOT, text=True, stderr=subprocess.DEVNULL
        ).strip() or fallback
    except (OSError, subprocess.CalledProcessError):
        return fallback


def parse_service_worker_assets() -> list[str]:
    source = (ROOT / "sw.js").read_text(encoding="utf-8")
    match = re.search(r"const\s+ASSETS\s*=\s*\[(.*?)\]\s*;", source, re.DOTALL)
    if match is None:
        raise SystemExit("Unable to locate the ASSETS array in sw.js")

    values: list[str] = []
    for single, double in re.findall(r"'([^']*)'|\"([^\"]*)\"", match.group(1)):
        raw = single or double
        if raw in {"./", ""}:
            continue
        normalized = raw[2:] if raw.startswith("./") else raw
        if normalized.startswith(("http://", "https://", "/")) or ".." in Path(normalized).parts:
            raise SystemExit(f"Unsafe web asset path: {raw}")
        if normalized not in values:
            values.append(normalized)

    if "index.html" not in values:
        raise SystemExit("sw.js must declare index.html")
    return values


def validate_index_references(asset_names: set[str]) -> None:
    html = (ROOT / "index.html").read_text(encoding="utf-8")
    references = re.findall(r"(?:src|href)=\"([^\"]+)\"", html)
    missing: list[str] = []
    for reference in references:
        if reference.startswith(("http://", "https://", "data:", "#")):
            continue
        normalized = reference[2:] if reference.startswith("./") else reference
        if normalized not in asset_names:
            missing.append(normalized)
    if missing:
        raise SystemExit("index.html references undeclared assets: " + ", ".join(sorted(set(missing))))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    assets = parse_service_worker_assets()
    if "sw.js" not in assets:
        assets.append("sw.js")
    validate_index_references(set(assets))

    output = args.output.resolve()
    if output.exists():
        shutil.rmtree(output)
    output.mkdir(parents=True)

    manifest: dict[str, str] = {}
    for name in assets:
        source = ROOT / name
        if not source.is_file() or source.stat().st_size == 0:
            raise SystemExit(f"Missing or empty web asset: {name}")
        destination = output / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
        manifest[name] = sha256(source)

    source_branch = os.environ.get("GITHUB_HEAD_REF") or os.environ.get("GITHUB_REF_NAME") or git_value(
        "rev-parse", "--abbrev-ref", "HEAD", fallback="android/tutorial-integration"
    )
    source_commit = os.environ.get("GITHUB_SHA") or git_value("rev-parse", "HEAD", fallback="unknown")

    (output / "asset-manifest.json").write_text(
        json.dumps(
            {
                "source_branch": source_branch,
                "source_commit": source_commit,
                "base_game_branch": "playtest-stable",
                "base_game_commit": BASE_GAME_COMMIT,
                "feature_set": ["original-web-game", "gdd-guided-tutorial"],
                "assets": manifest,
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    print(f"Packed {len(assets)} web assets into {output}")


if __name__ == "__main__":
    main()
