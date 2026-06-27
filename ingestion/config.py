"""Read and validate config/indicators.yml — the single source of truth.
No network calls here; this only parses and flattens the config so the
pull modules have clean, validated lists to work from.
"""
from pathlib import Path
import yaml

# Resolve the config path relative to the repo root, not the cwd,
# so this works whether run from root or elsewhere.
CONFIG_PATH = Path(__file__).resolve().parent.parent / "config" / "indicators.yml"


def load_config(path: Path = CONFIG_PATH) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def get_window(cfg: dict) -> tuple[int, int]:
    w = cfg["project"]["analysis_window"]
    return w["start"], w["end"]


def get_countries(cfg: dict) -> list[str]:
    """All economies to pull: the six WB + EU aggregate + comparators."""
    c = cfg["countries"]
    six = c["western_balkans"]
    eu = [c["benchmarks"]["eu_aggregate"]]
    comparators = c["benchmarks"]["comparators"]
    return six + eu + comparators


def get_wdi_indicators(cfg: dict) -> list[dict]:
    """Flatten all WDI codes across category blocks into one list.
    Each entry: {code, name, coverage, category}.
    """
    out = []
    for category, items in cfg["wdi_indicators"].items():
        for item in items:
            out.append({
                "code": item["code"],
                "name": item["name"],
                "coverage": item.get("coverage"),
                "category": category,
            })
    return out


def get_wgi_indicators(cfg: dict) -> list[dict]:
    """WGI codes (source=3). Each entry: {code, name}."""
    return [
        {"code": i["code"], "name": i["name"]}
        for i in cfg["wgi_indicators"]["indicators"]
    ]


if __name__ == "__main__":
    cfg = load_config()
    start, end = get_window(cfg)
    countries = get_countries(cfg)
    wdi = get_wdi_indicators(cfg)
    wgi = get_wgi_indicators(cfg)

    print(f"Window: {start}-{end}")
    print(f"Countries ({len(countries)}): {countries}")
    print(f"WDI indicators ({len(wdi)}):")
    for w in wdi:
        print(f"  [{w['category']}] {w['code']} — {w['coverage']}")
    print(f"WGI indicators ({len(wgi)}):")
    for w in wgi:
        print(f"  {w['code']}")