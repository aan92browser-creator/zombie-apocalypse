import json
import os
import sys
import zipfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
JAR = os.path.join(ROOT, "tools", "vanilla_data", "client-1.20.1.jar")
VANILLA_OUT = os.path.join(ROOT, "tools", "vanilla_data", "loot")
MANIFEST = os.path.join(ROOT, "tools", "loot_manifest.json")
OUT = os.path.join(
    ROOT,
    "pack", "overrides", "config", "openloader", "data", "zombie_apocalypse",
    "data", "minecraft", "loot_tables", "chests",
)

TABLES = [
    "simple_dungeon",
    "abandoned_mineshaft",
    "stronghold_library",
    "stronghold_corridor",
    "woodland_mansion",
    "igloo_chest",
    "shipwreck_treasure",
    "pillager_outpost",
]

NEW_POOL = {
    "rolls": 1,
    "entries": [
        {
            "type": "minecraft:item",
            "name": "minecraft:potion",
            "weight": 10,
            "functions": [
                {"function": "minecraft:set_nbt", "tag": '{Potion:"minecraft:water"}'},
                {
                    "function": "minecraft:set_count",
                    "count": {"type": "minecraft:uniform", "min": 1, "max": 3},
                },
            ],
        },
        {
            "type": "minecraft:item",
            "name": "minecraft:cooked_beef",
            "weight": 10,
            "functions": [
                {
                    "function": "minecraft:set_count",
                    "count": {"type": "minecraft:uniform", "min": 2, "max": 5},
                }
            ],
        },
        {
            "type": "minecraft:item",
            "name": "tacz:ammo",
            "weight": 8,
            "functions": [
                {"function": "minecraft:set_nbt", "tag": '{AmmoId:"tacz:9mm"}'},
                {
                    "function": "minecraft:set_count",
                    "count": {"type": "minecraft:uniform", "min": 8, "max": 16},
                },
            ],
        },
        {
            "type": "minecraft:item",
            "name": "minecraft:leather",
            "weight": 6,
            "functions": [
                {
                    "function": "minecraft:set_count",
                    "count": {"type": "minecraft:uniform", "min": 1, "max": 3},
                }
            ],
        },
        {
            "type": "minecraft:item",
            "name": "minecraft:iron_ingot",
            "weight": 3,
        },
        {
            "type": "minecraft:item",
            "name": "tacz:modern_kinetic_gun",
            "weight": 1,
            "functions": [
                {"function": "minecraft:set_nbt", "tag": '{GunId:"tacz:glock_17"}'}
            ],
        },
    ],
}


def canon(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"))


def main():
    if not os.path.exists(JAR):
        print("missing vanilla jar: " + JAR, file=sys.stderr)
        return 1
    os.makedirs(VANILLA_OUT, exist_ok=True)
    os.makedirs(OUT, exist_ok=True)

    manifest = {"tables": {}}
    problems = []
    with zipfile.ZipFile(JAR) as jar:
        for name in TABLES:
            entry = "data/minecraft/loot_tables/chests/" + name + ".json"
            try:
                vanilla = json.loads(jar.read(entry).decode("utf-8"))
            except KeyError:
                problems.append(name + ": not in jar")
                continue
            original_pools = vanilla.get("pools", [])
            if not isinstance(original_pools, list) or not original_pools:
                problems.append(name + ": no original pools")
                continue
            if any(canon(p) == canon(NEW_POOL) for p in original_pools):
                problems.append(name + ": new pool already present in vanilla")

            with open(os.path.join(VANILLA_OUT, name + ".json"), "w", encoding="utf-8") as f:
                json.dump(vanilla, f, indent=2)
                f.write("\n")

            merged = dict(vanilla)
            merged["pools"] = list(original_pools) + [NEW_POOL]

            out_path = os.path.join(OUT, name + ".json")
            with open(out_path, "w", encoding="utf-8") as f:
                json.dump(merged, f, indent=2)
                f.write("\n")

            written = json.loads(open(out_path, encoding="utf-8").read())
            pools = written.get("pools", [])
            if len(pools) != len(original_pools) + 1:
                problems.append(name + ": pool count %d" % len(pools))
            for i, pool in enumerate(original_pools):
                if canon(pools[i]) != canon(pool):
                    problems.append(name + ": original pool %d changed" % i)
            if canon(pools[-1]) != canon(NEW_POOL):
                problems.append(name + ": new pool not last")

            manifest["tables"][name] = {
                "original_pools": len(original_pools),
                "output_pools": len(pools),
            }

    with open(MANIFEST, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
        f.write("\n")

    if problems:
        for p in problems:
            print("FAIL " + p)
        return 1
    print("loot: %d tables" % len(TABLES))
    return 0


if __name__ == "__main__":
    sys.exit(main())
