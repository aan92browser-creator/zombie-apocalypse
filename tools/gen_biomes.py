import json
import os
import sys
import urllib.request
import zipfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
VANILLA_JAR = os.path.join(ROOT, "tools", "vanilla_data", "client-1.20.1.jar")
BIOME_SRC = os.path.join(ROOT, "tools", "vanilla_data", "biome")
PACK = os.path.join(
    ROOT, "pack", "overrides", "config", "openloader", "data", "zombie_apocalypse"
)
OUT = os.path.join(PACK, "data", "minecraft", "worldgen", "biome")

SKIP = {
    "nether_wastes", "soul_sand_valley", "crimson_forest", "warped_forest",
    "basalt_deltas", "the_end", "small_end_islands", "end_midlands",
    "end_highlands", "end_barrens",
}

EFFECTS = {
    "sky_color": 0x6E7F96,
    "fog_color": 0xC7D4E0,
    "water_color": 0x3F76E4,
    "water_fog_color": 0x050533,
    "grass_color": 0x8FA58C,
    "foliage_color": 0x7C8F79,
}


def fetch():
    os.makedirs(os.path.dirname(VANILLA_JAR), exist_ok=True)
    if not os.path.exists(VANILLA_JAR):
        with urllib.request.urlopen(
            "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"
        ) as r:
            manifest = json.load(r)
        url = next(v["url"] for v in manifest["versions"] if v["id"] == "1.20.1")
        with urllib.request.urlopen(url) as r:
            version = json.load(r)
        jar_url = version["downloads"]["client"]["url"]
        print("downloading", jar_url)
        urllib.request.urlretrieve(jar_url, VANILLA_JAR)
    os.makedirs(BIOME_SRC, exist_ok=True)
    with zipfile.ZipFile(VANILLA_JAR) as z:
        for name in z.namelist():
            if name.startswith("data/minecraft/worldgen/biome/") and name.endswith(".json"):
                with open(os.path.join(BIOME_SRC, os.path.basename(name)), "wb") as f:
                    f.write(z.read(name))
    print("vanilla biomes:", len(os.listdir(BIOME_SRC)))


def cold_temp(orig):
    if orig <= 0.0:
        return -0.5
    if orig >= 1.0:
        return 0.05
    if orig >= 0.8:
        return 0.0
    if orig >= 0.3:
        return -0.1
    return -0.25


def generate():
    os.makedirs(OUT, exist_ok=True)
    count = 0
    for name in sorted(os.listdir(BIOME_SRC)):
        biome_id = name[:-5]
        if biome_id in SKIP:
            continue
        with open(os.path.join(BIOME_SRC, name), encoding="utf-8") as f:
            data = json.load(f)
        data["temperature"] = cold_temp(float(data.get("temperature", 0.5)))
        data["has_precipitation"] = True
        data.setdefault("effects", {})
        data["effects"].update(EFFECTS)
        with open(os.path.join(OUT, name), "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
        count += 1
    print("generated", count)

    village_dir = os.path.join(PACK, "data", "minecraft", "worldgen", "structure_set")
    os.makedirs(village_dir, exist_ok=True)
    villages = {
        "structures": [],
        "placement": {
            "type": "minecraft:random_spread",
            "salt": 10387312,
            "separation": 8,
            "spacing": 34,
        },
    }
    with open(os.path.join(village_dir, "villages.json"), "w", encoding="utf-8") as f:
        json.dump(villages, f, indent=2)
    print("villages removed")


if __name__ == "__main__":
    if "--fetch" in sys.argv or not os.path.isdir(BIOME_SRC) or not os.listdir(BIOME_SRC):
        fetch()
    if "--fetch-only" not in sys.argv:
        generate()
