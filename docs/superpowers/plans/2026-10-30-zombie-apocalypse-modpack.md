# Zombie Apocalypse Salju — Rencana Implementasi

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Membangun modpack Forge 1.20.1 "Zombie Apocalypse Salju" (mod + KubeJS + datapack) yang bisa di-import ke Modrinth App dan dimainkan di PC pemilik pack.

**Architecture:** Mod pihak ketiga menangani sistem berat (suhu, kehausan, senjata, quest, performa, shader, struktur). KubeJS menjadi satu-satunya otoritas untuk spawn zombie, horde, role zombie, mutant, guard struktur, starter kit, dan resep. Datapack mengubah semua biome jadi dingin dan menghapus desa. Verifikasi otomatis lewat server Forge headless + RCON; verifikasi visual lewat checklist main manual.

**Tech Stack:** Minecraft 1.20.1, Forge 47.3.0, KubeJS 2001.x, FTB Quests, Cold Sweat, Thirst Was Taken, TaCZ, PowerShell 5.1+, Python 3.14, Java 17 (server uji).

**Spec:** `docs/2026-10-30-zombie-apocalypse-modpack-design.md`

## Global Constraints

- Minecraft 1.20.1, Forge 47.3.0, datapack `pack_format: 15`.
- Deliverable: `.mrpack` untuk Modrinth App; mod diunduh dari Modrinth CDN, bukan dibundel.
- FTB Quests + FTB Library + FTB Teams diunduh manual dari CurseForge (tidak ada di Modrinth).
- Tanpa mod Java custom. Semua mekanik khas lewat KubeJS, datapack, atau config.
- Instance final: `D:\MinecraftPacks\ZombieApocalypse`; alokasi RAM 8G.
- Performa: 60 FPS di luar horde, >=45 FPS saat horde, cap 40 zombie.
- Bahasa: quest/pesan/tooltip Indonesia; nama item dan senjata English.
- Python hanya lewat path absolut: `C:\Users\Random\AppData\Local\Python\pythoncore-3.14-64\python.exe`.
- Java sistem (25) tidak kompatibel dengan Forge 1.20.1; server uji memakai JRE 17 portabel di `tools/java17/`.
- Angka gameplay: horde hari `day % 10 == 0`, lock tidur tick 12000, gelombang 14000/16000/18000, selesai 23000, `8 + 4*(index-1)` per gelombang (cap 40), ring 32-48 blok, mutant `min(0.03 + 0.004*(hari-30), 0.30)`, role hari 3/7/12/20/30, break rate 60 tick (30 saat horde), radius kejar 8, safe radius dunia 16.

## Review Focus

1. Mod hilang/versi salah -> server gagal boot: dicek di Task 2 dan Task 3 (log harus "Done" tanpa "Missing or unsupported mandatory dependencies").
2. Error satu file KubeJS mematikan horde/kit tanpa pesan jelas: dicek di Task 5 (`/zombieapoc ping` harus menjawab).
3. Override biome kehilangan field wajib -> crash/ dunia kosong: dicek di Task 4 (validator membandingkan key set dengan vanilla).
4. Sleep lock memblokir bed di malam biasa: dicek di Task 7 (`blockSleep` false di hari 5, true di hari 10 tick >= 12000).
5. Cap horde jebol -> lag di Ryzen 5 5600: dicek di Task 7 (jumlah `@e[tag=za_horde]` <= 40 setelah semua gelombang).

---

### Task 1: Scaffold proyek dan manifest mod

**Files:**
- Create: `.gitignore`, `tools/mods.json`, `pack/overrides/kubejs/{startup_scripts,server_scripts}/.gitkeep`, `pack/manual-mods/.gitkeep`, `pack/overrides/config/openloader/data/zombie_apocalypse/pack.mcmeta`, `README.md`

**Interfaces:**
- Produces: `tools/mods.json` = array `{slug: string, side: "both"|"client", manual?: true}`; dipakai Task 2, 3, 13.

- [ ] **Step 1: Inisialisasi repo dan folder**

```bash
git init
mkdir -p tools pack/overrides/kubejs/startup_scripts pack/overrides/kubejs/server_scripts pack/manual-mods pack/overrides/config/openloader/data/zombie_apocalypse dist
```

`.gitignore`: `server/`, `dist/`, `tools/java17/`, `tools/vanilla_data/`, `pack/overrides/mods/*.jar`, `run/`, `*.log`.

- [ ] **Step 2: Tulis `tools/mods.json`**

41 entri: performa (embeddium, oculus, modernfix, ferrite-core, entityculling, canary, clumps, ai-improvements, memoryleakfix), survival (cold-sweat, glitchcore, thirst-was-taken, zombie-awareness), tempur (timeless-and-classics-zero), skrip (kubejs, rhino, architectury-api, openloader), struktur (when-dungeons-arise, structory, structory-towers, yungs-better-dungeons, yungs-api, additional-structures), salju (snow-real-magic, snow-under-trees), QoL (sophisticated-backpacks, sophisticated-core, corpse, jade, appleskin, waystones), atmosfer (ambientsounds, sound-physics-remastered, enhancedvisuals), opsional (pehkui, chunky). Tiga entri manual: `ftb-quests-forge`, `ftb-library-forge`, `ftb-teams-forge` dengan `"manual": true`. Tandai `side: "client"` untuk embeddium, oculus, enhancedvisuals, jade, appleskin, ambientsounds, sound-physics-remastered.

- [ ] **Step 3: Validasi manifest**

```powershell
$m = Get-Content tools/mods.json -Raw | ConvertFrom-Json
if ($m.Count -ne 41) { throw "count=$($m.Count)" }
$m | Where-Object { $_.side -notin @('both','client') } | ForEach-Object { throw "bad side: $($_.slug)" }
"manifest ok: $($m.Count)"
```

Expected: `manifest ok: 41`.

- [ ] **Step 4: Isi `pack.mcmeta`**

`{"pack":{"pack_format":15,"description":"Zombie Apocalypse Salju"}}`.

- [ ] **Step 5: Commit**

```bash
git add .gitignore tools/mods.json pack README.md
git commit -m "chore: scaffold pack project and mod manifest"
```

---

### Task 2: Unduh mod dari Modrinth + lockfile

**Files:**
- Create: `tools/fetch_mods.ps1`, `tools/mods.lock.json`, `pack/overrides/mods/*.jar`

**Interfaces:**
- Consumes: `tools/mods.json`.
- Produces: `tools/mods.lock.json` = array `{slug, versionId, file, sha1, sha512, url, side}`; dipakai Task 3 dan 13.

- [ ] **Step 1: Tulis mode verifikasi lebih dulu**

`tools/fetch_mods.ps1 -Verify` keluar dengan kode 1 dan pesan `MISSING <slug>` untuk setiap entri non-manual yang jar-nya tidak ada.

- [ ] **Step 2: Jalankan untuk memastikan gagal**

Run: `powershell -File tools/fetch_mods.ps1 -Verify`
Expected: FAIL, 38 baris `MISSING`.

- [ ] **Step 3: Implementasi unduhan**

Untuk tiap entri non-manual: `GET https://api.modrinth.com/v2/project/<slug>/version?game_versions=["1.20.1"]&loaders=["forge"]` (header `User-Agent: zombieapoc-pack/1.0`), ambil versi pertama (terbaru), unduh `files[0].url` ke `pack/overrides/mods/`, hitung SHA1/SHA512 dengan `Get-FileHash`, tulis lockfile. Gagal keras bila jumlah versi 0 (mod tidak mendukung 1.20.1 Forge) — jangan lanjut diam-diam.

- [ ] **Step 4: Jalankan unduhan dan verifikasi**

Run: `powershell -File tools/fetch_mods.ps1; powershell -File tools/fetch_mods.ps1 -Verify`
Expected: `downloaded 38`, `lock ok: 38`, exit 0.

- [ ] **Step 5: Commit lockfile**

```bash
git add tools/fetch_mods.ps1 tools/mods.lock.json
git commit -m "feat: fetch pinned Modrinth mods and lock versions"
```

---

### Task 3: Server Forge headless + harness RCON

**Files:**
- Create: `tools/server_test/setup.ps1`, `tools/server_test/start.ps1`, `tools/server_test/rcon.ps1`, `tools/server_test/server.properties`, `tools/server_test/stop.ps1`

**Interfaces:**
- Produces: `tools/server_test/rcon.ps1 -Command "<cmd>"` -> mencetak respons RCON (string). Dipakai semua task sesudahnya.

- [ ] **Step 1: Pasang JRE 17 portabel**

Unduh `https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jre/hotspot/normal/eclipse` -> zip -> ekstrak ke `tools/java17/`. Verifikasi: `tools/java17/<folder>/bin/java.exe -version` melaporkan `17.` Semua perintah Java di bawah memakai path absolut ini (bukan `java` sistem yang versi 25).

- [ ] **Step 2: Pasang server Forge 1.20.1**

Unduh installer `https://maven.minecraftforge.net/net/minecraftforge/forge/1.20.1-47.3.0/forge-1.20.1-47.3.0-installer.jar`, jalankan `tools/java17/<folder>/bin/java.exe -jar <installer> --installServer server/`. Tulis `server/eula.txt` (`eula=true`) dan `server/server.properties`: `online-mode=false`, `enable-rcon=true`, `rcon.port=25575`, `rcon.password=za`, `view-distance=6`, `simulation-distance=6`, `max-tick-time=-1`, `level-seed=za-test`, `spawn-protection=0`, `difficulty=normal`.

- [ ] **Step 3: Salin mod + datapack ke server**

Salin jar dengan `side != "client"` ke `server/mods/`; salin `pack/overrides/config/openloader/data/zombie_apocalypse` ke `server/config/openloader/data/`; salin `pack/overrides/kubejs` ke `server/kubejs/`.

- [ ] **Step 4: Implementasi klien RCON minimal**

Protokol: paket = `length:int32le`, `id:int32le`, `type:int32le`, payload UTF-8 + 2 byte null. Auth = type 3 (id 1), command = type 2 (id 2). Baca paket respons per header 12 byte. `rcon.ps1 -Command "list"` mencetak payload respons.

- [ ] **Step 5: Uji boot**

Run: `powershell -File tools/server_test/start.ps1` (tunggu log memuat `Done (`), lalu `powershell -File tools/server_test/rcon.ps1 -Command "list"`, lalu `stop.ps1`.
Expected: log berisi `Done (`, tanpa `Missing or unsupported mandatory dependencies`; RCON membalas `There are 0 of a max of 20 players online`.

- [ ] **Step 6: Commit**

```bash
git add tools/server_test
git commit -m "test: add headless forge server and rcon harness"
```

---

### Task 4: Datapack biome dingin + hapus desa

**Files:**
- Create: `tools/gen_biomes.py`, `tools/verify_datapack.ps1`, `pack/overrides/config/openloader/data/zombie_apocalypse/data/minecraft/worldgen/biome/*.json`, `.../data/minecraft/worldgen/structure_set/villages.json`

**Interfaces:**
- Produces: satu JSON per biome vanilla dengan key set identik vanilla, `temperature <= 0.1`, `precipitation == "snow"`.

- [ ] **Step 1: Siapkan data vanilla**

`tools/gen_biomes.py --fetch` mengunduh manifest versi Mojang, mengambil URL client jar 1.20.1, dan mengekstrak `data/minecraft/worldgen/biome/*.json` ke `tools/vanilla_data/biome/`. Catat jumlah file.

- [ ] **Step 2: Tulis validator lebih dulu**

`tools/verify_datapack.ps1` memeriksa: jumlah file output == jumlah file vanilla; untuk setiap file, key set sama persis dengan sumber; `temperature <= 0.1`; `precipitation == "snow"`; `effects.water_color`, `effects.sky_color`, `effects.fog_color` ada. Keluar kode 1 dengan daftar pelanggaran.

- [ ] **Step 3: Jalankan validator untuk memastikan gagal**

Run: `powershell -File tools/verify_datapack.ps1`
Expected: FAIL `no output files`.

- [ ] **Step 4: Implementasi generator**

Pemetaan suhu dari suhu asli biome: `>=1.0 -> 0.05`, `0.8..1.0 -> 0.0`, `0.3..0.8 -> -0.1`, `<0.3 -> -0.25`, biome yang sudah snowy -> `-0.5`. `precipitation = "snow"`. Efek: `water_color 0x3F76E4`, `sky_color 0x6E7F96`, `fog_color 0xC7D4E0`, `grass_color 0x8FA58C`, `foliage_color 0x7C8F79`. Jangan menyentuh `features`, `carvers`, `spawners`, `spawn_costs`.

- [ ] **Step 5: Override structure set desa**

`villages.json`: `{"structures": []}`. Tambahkan pemeriksaan di validator (array kosong).

- [ ] **Step 6: Generate + validasi + boot server**

Run: `"C:\Users\Random\AppData\Local\Python\pythoncore-3.14-64\python.exe" tools/gen_biomes.py; powershell -File tools/verify_datapack.ps1; powershell -File tools/server_test/start.ps1`
Expected: validator `ok: <n> biomes`; log server memuat `zombie_apocalypse` sebagai datapack; `rcon.ps1 -Command "datapack list"` menampilkan pack aktif.

- [ ] **Step 7: Commit**

```bash
git add tools/gen_biomes.py tools/verify_datapack.ps1 pack/overrides/config/openloader
git commit -m "feat: freeze all biomes and remove villages via datapack"
```

---

### Task 5: KubeJS inti, spawn control, kunci dimensi

**Files:**
- Create: `pack/overrides/kubejs/server_scripts/00_util.js`, `.../10_spawn_control.js`, `.../90_debug.js`

**Interfaces:**
- Produces: `global.za` dengan `day(level): int`, `isHordeDay(day): bool`, `hordeIndex(day): int`, `blockSleep(level): bool`, `cfg` (objek konstanta dari Global Constraints), dan command `/zombieapoc <ping|day|addDays <n>|isHordeDay <n>|blockSleep|canSpawn <entityId>>`. Command debug lain didaftarkan oleh task yang memilikinya.

- [ ] **Step 1: Cek baseline gagal**

Run: `rcon.ps1 -Command "zombieapoc ping"`
Expected: `Unknown or incomplete command`.

- [ ] **Step 2: Implementasi `00_util.js` + `90_debug.js`**

`cfg` memuat semua angka Global Constraints. Daftarkan command lewat `ServerEvents.commandRegistry` dengan `Commands.literal('zombieapoc')` dan subcommand. `blockSleep(level)`: `level.day % 10 == 0 && level.timeOfDay >= 12000`. `addDays(n)` hanya untuk pengujian: `server.runCommandSilent('time add ' + n * 24000)`.

- [ ] **Step 3: Uji command inti**

Run: `rcon.ps1 -Command "reload"` lalu `rcon.ps1 -Command "zombieapoc ping"`, `-Command "time query day"`, `-Command "zombieapoc day"`.
Expected: `pong`; angka `day` sama dengan hasil `time query day`.

- [ ] **Step 4: Implementasi `10_spawn_control.js`**

`EntityEvents.checkSpawn`: batalkan bila `entity.type` bukan `minecraft:zombie`, `minecraft:husk`, `minecraft:drowned`, atau `minecraft:zombie_villager` (zombie_villager hanya boleh dari konversi, bukan spawn alami). Buka `/zombieapoc canSpawn <entityId>` yang memanggil predikat yang sama.

- [ ] **Step 5: Kunci Nether/End**

`BlockEvents.rightClicked` pada obsidian dengan flint & steel yang membentuk frame -> `event.cancel()`. `ItemEvents.rightClicked` eye of ender pada `end_portal_frame` -> `event.cancel()`. `PlayerEvents.tick` (tiap 100 tick): bila `player.level.dimension` adalah nether/end -> teleport ke overworld spawn.

- [ ] **Step 6: Uji**

Run: `zombieapoc canSpawn minecraft:skeleton` -> `false`; `zombieapoc canSpawn minecraft:zombie` -> `true`; `zombieapoc canSpawn minecraft:husk` -> `true`.
Expected sesuai nilai di atas.

- [ ] **Step 7: Commit**

```bash
git add pack/overrides/kubejs
git commit -m "feat: kubejs core, zombie-only spawns, dimension locks"
```

---

### Task 6: Starter kit

**Files:**
- Create: `pack/overrides/kubejs/server_scripts/20_starter_kit.js`

**Interfaces:**
- Consumes: `global.za.cfg`, item insulated dari Task 10.
- Produces: `za.giveKit(player)`, `za.kitPreview(): string[]` (daftar `"<count>x <itemId>"`).

- [ ] **Step 1: Uji gagal**

Run: `zombieapoc kitPreview`
Expected: `Unknown or incomplete command`.

- [ ] **Step 2: Implementasi**

`za.giveKit(player: Player)`: insulated leather set (4), pistol TaCZ + 64 peluru, 8 cooked beef, 4 water bottle, 8 torch. `PlayerEvents.loggedIn`: bila `player.persistentData.zaKit` belum ada -> `giveKit`, set true, kirim pesan Indonesia. `kitPreview` mengembalikan daftar stack yang sama (tanpa memberi).

- [ ] **Step 3: Uji**

Run: `zombieapoc kitPreview`
Expected: 9 baris stack dengan jumlah sesuai (mis. `64x tacz:ammo`, `4x minecraft:potion`).

- [ ] **Step 4: Commit**

```bash
git add pack/overrides/kubejs/server_scripts/20_starter_kit.js
git commit -m "feat: first-join starter kit"
```

---

### Task 7: Horde terjadwal + sleep lock

**Files:**
- Create: `pack/overrides/kubejs/server_scripts/30_horde.js`

**Interfaces:**
- Consumes: `za.cfg`, `za.isHordeDay`, `za.blockSleep`.
- Produces: `za.startHorde(level, hordeIndex)`, `za.spawnWave(level, waveIndex, hordeIndex)`, `za.endHorde(level)`, `za.hordeStatus(level): string`, command `zombieapoc sethorde <0|1|index>`, `zombieapoc hordeStatus`.

- [ ] **Step 1: Uji gagal**

Run: `zombieapoc hordeStatus`
Expected: unknown command.

- [ ] **Step 2: Implementasi scheduler**

`ServerEvents.tick` (cek tiap 20 tick): bila `isHordeDay(day)` dan `timeOfDay >= 13000` dan belum aktif -> `startHorde`; saat `14000/16000/18000` -> `spawnWave` sekali per gelombang (flag di `server.persistentData.zaWave`); saat `>=23000` atau hari berganti -> `endHorde`. Spawn memakai `server.runCommandSilent('summon minecraft:zombie <x> <y> <z> {Tags:["za_horde"],...}')` pada ring 32-48 blok mengelilingi player terdekat (fallback: world spawn). Jumlah per gelombang `8 + 4*(index-1)`, berhenti bila jumlah `@e[tag=za_horde]` sudah 40. `endHorde` menjalankan `kill @e[tag=za_horde]`.

- [ ] **Step 3: Implementasi sleep lock**

`BlockEvents.rightClicked` pada `*_bed`: bila `za.blockSleep(level)` -> `event.cancel()` + actionbar `"Tidak bisa tidur saat horde!"` (Indonesia).

- [ ] **Step 4: Uji lewat RCON**

```
zombieapoc addDays 9            # sampai hari +9
time set 13000
zombieapoc hordeStatus          -> "active index=1 day=10 count=<n>"
execute if entity @e[tag=za_horde]   -> "Test passed"
zombieapoc hordeStatus          # setelah gelombang 14000/16000/18000
execute if entity @e[tag=za_horde,limit=41]  -> "Test failed" (artinya tidak pernah >40)
zombieapoc sethorde 0
zombieapoc hordeStatus          -> "idle"
execute if entity @e[tag=za_horde]   -> "Test failed"
```
Gunakan `time set 14000`, `16000`, `18000` bergantian untuk memicu tiap gelombang, tiap kali tunggu 40 tick. **n <= 40** wajib.

- [ ] **Step 5: Uji predikat sleep**

`time set 12000` pada hari 10 -> `zombieapoc blockSleep` = `true`; `time set 12000` pada hari 5 -> `false`.
Expected sesuai.

- [ ] **Step 6: Commit**

```bash
git add pack/overrides/kubejs/server_scripts/30_horde.js
git commit -m "feat: scheduled hordes with sleep lock and entity cap"
```

---

### Task 8: Role zombie, eskalasi harian, mutant, penghancuran blok

**Files:**
- Create: `pack/overrides/kubejs/server_scripts/40_zombie_roles.js`

**Interfaces:**
- Consumes: `za.cfg`.
- Produces: `za.roleFor(day, rng): string`, `za.isMutantRoll(day, rng): bool`, `za.applyRole(entity, role)`, `za.canBreak(role, blockId): bool`, command `zombieapoc weights <day>`, `zombieapoc canBreak <role> <blockId>`, `zombieapoc spawnRole <role>`, `zombieapoc mutantChance <day>`.

- [ ] **Step 1: Uji predikat gagal**

Run: `zombieapoc canBreak pickaxe minecraft:stone`
Expected: unknown command.

- [ ] **Step 2: Implementasi tabel role**

| Hari | Role yang mungkin |
|---|---|
| 1-2 | `base` |
| 3-6 | `base`, `armored` |
| 7-11 | + `pickaxe`, `axe` |
| 12-19 | + `pearl` |
| 20-29 | `armored` naik ke iron |
| 30+ | + `mutant` (flag, bukan role eksklusif) |

`applyRole` memberi armor + senjata jarak dekat via NBT summon/merge dan tag `za_role_<role>`. `mutant`: HP 3-4x, damage naik, knockback resistance, `scale set 1.4` (Pehkui) bila tersedia.

- [ ] **Step 3: Implementasi perilaku tick**

`ServerEvents.tick` tiap 10 tick, hanya entitas bertag `za_role_*` dalam 32 blok dari player:
- `pearl`: 15% per cek, cooldown 160 tick, teleport 3-5 blok di belakang player, konsumsi ender pearl, suara.
- `pickaxe`/`axe`: bila player dalam 8 blok, hancurkan 1 blok menghadap zombie bila `canBreak` true, cooldown 60 tick normal / 30 saat horde, lewati bila dalam 16 blok world spawn kecuali horde.

- [ ] **Step 4: Uji**

```
zombieapoc canBreak pickaxe minecraft:stone      -> true
zombieapoc canBreak pickaxe minecraft:oak_log    -> false
zombieapoc canBreak axe minecraft:oak_log        -> true
zombieapoc canBreak axe minecraft:stone          -> false
zombieapoc mutantChance 30                        -> 0.03
zombieapoc mutantChance 60                        -> 0.15
zombieapoc mutantChance 200                       -> 0.30
zombieapoc spawnRole pearl                        -> "spawned za_role_pearl"
execute if entity @e[tag=za_role_pearl]           -> "Test passed"
```

- [ ] **Step 5: Commit**

```bash
git add pack/overrides/kubejs/server_scripts/40_zombie_roles.js
git commit -m "feat: day-scaled zombie roles, mutants, block breaking rules"
```

---

### Task 9: Guard struktur + loot

**Files:**
- Create: `pack/overrides/kubejs/server_scripts/50_structure_guards.js`, `tools/gen_loot.py`, `pack/overrides/config/openloader/data/zombie_apocalypse/data/minecraft/loot_tables/chests/*.json`

**Interfaces:**
- Consumes: `za.applyRole`, `za.cfg`.
- Produces: `za.guardAt(level, pos, day): bool` (false bila sudah pernah), command `zombieapoc guardTest`.

- [ ] **Step 1: Uji gagal**

Run: `zombieapoc guardTest`
Expected: unknown command.

- [ ] **Step 2: Implementasi guard**

`BlockEvents.rightClicked` pada chest/barrel yang punya loot table: bila pos belum tercatat di `server.persistentData.zaGuards` (maks 500 entri) -> tandai, spawn 2-4 zombie bertag `za_guard` sesuai hari (memakai tabel role Task 8).

- [ ] **Step 3: Generator loot datapack**

`tools/gen_loot.py` membaca loot table chest vanilla 1.20.1 (`chests/simple_dungeon`, `chests/abandoned_mineshaft`, `chests/stronghold_library`, `chests/stronghold_corridor`, `chests/woodland_mansion`, `chests/igloo_chest`, `chests/shipwreck_treasure`, `chests/pillager_outpost`) lalu menambah satu pool: `water bottle` (weight 10), `cooked_beef` (10), `tacz ammo` (8), `leather` (6), `iron_ingot` (3), pistol (1). Assertion: setiap output tetap punya pool asli + satu pool baru.

- [ ] **Step 4: Uji**

```
zombieapoc guardTest 0 100 0   -> "guarded 3" (pertama)
zombieapoc guardTest 0 100 0   -> "already guarded" (kedua, posisi sama)
powershell -File tools/verify_datapack.ps1  -> loot: 8 tables, +1 pool each
loot spawn 0 100 0 loot minecraft:chests/simple_dungeon
execute if entity @e[type=item,distance=..8,x=0,y=100,z=0]  -> "Test passed"
```

- [ ] **Step 5: Commit**

```bash
git add pack/overrides/kubejs/server_scripts/50_structure_guards.js tools/gen_loot.py pack/overrides/config/openloader
git commit -m "feat: structure guards and expanded structure loot"
```

---

### Task 10: Resep, amunisi, air, armor wool

**Files:**
- Create: `pack/overrides/kubejs/server_scripts/60_recipes.js`, `pack/overrides/kubejs/startup_scripts/insulated_armor.js`, `pack/overrides/config/openloader/data/zombie_apocalypse/data/coldsweat/` (hasil probe)

**Interfaces:**
- Produces: item `kubejs:insulated_leather_{helmet,chestplate,leggings,boots}`, `za.recipeCheck(id): bool`.

- [ ] **Step 1: Probe schema Cold Sweat dan TaCZ**

Ekstrak jar di `pack/overrides/mods/`; catat: (a) path dan bentuk JSON insulasi Cold Sweat (per item atau tag), (b) id tipe resep amunisi TaCZ. Tulis temuan sebagai komentar di `60_recipes.js`. Bila Cold Sweat tidak mendukung insulasi data-driven: pakai fallback atribut `generic:armor` + efek hangat tick.

- [ ] **Step 2: Uji gagal**

Run: `zombieapoc recipeCheck kubejs:insulated_leather_helmet`
Expected: unknown command / false.

- [ ] **Step 3: Implementasi item + resep**

Item armor via `StartupEvents.registry('item')` (tipe armor bila didukung; fallback `basic` + attribute). Resep: insulated per bagian = leather armor + 2 wool (shapeless). Amunisi TaCZ: 1 gunpowder + 1 iron nugget + 1 paper -> 8 butir. Gunpowder: charcoal + flint + sand. Air: 4 snowball + 1 glass bottle -> water bottle. Backpack: 5 leather + 2 wool + 2 string.

- [ ] **Step 4: Uji**

```
zombieapoc recipeCheck kubejs:insulated_leather_helmet  -> true
zombieapoc recipeCheck kubejs:ammo_basic                 -> true
zombieapoc recipeCheck kubejs:gunpowder                  -> true
zombieapoc recipeCheck kubejs:water_bottle               -> true
zombieapoc recipeCheck kubejs:backpack                    -> true
```

- [ ] **Step 5: Commit**

```bash
git add pack/overrides/kubejs pack/overrides/config/openloader
git commit -m "feat: insulated wool armor, easy ammo, water and backpack recipes"
```

---

### Task 11: FTB Quests + mod manual

**Files:**
- Create: `pack/manual-mods/README.md`, `pack/overrides/config/ftbquests/quests/{data.snbt,chapters/*.snbt}`

**Interfaces:**
- Consumes: item dari Task 10, role dari Task 8.

- [ ] **Step 1: Unduh 3 jar manual**

Manusia mengunduh FTB Quests, FTB Library, FTB Teams untuk 1.20.1 Forge dari CurseForge ke `pack/manual-mods/`. README mencatat nama file dan versi.

- [ ] **Step 2: Tulis questline (Indonesia)**

7 chapter: Hari Pertama, Dingin, Haus, Senjata, Malam ke-10, Benteng, Mutasi. Tiap chapter 3-5 quest dengan task item/kill/dimension dan reward (amunisi, makanan, air, material). Chapter "Hari Pertama" memakai task `checkmark` untuk memberi arahan.

- [ ] **Step 3: Uji muat**

Server: salin jar manual ke `server/mods/`, boot, cek log tanpa error `ftbquests`. Klien: buka quest book (manual, lihat Task 14).

- [ ] **Step 4: Commit**

```bash
git add pack/manual-mods pack/overrides/config/ftbquests
git commit -m "feat: indonesian questline for survival progression"
```

---

### Task 12: Config, shader, profil performa

**Files:**
- Create: `pack/overrides/config/*.toml`, `pack/overrides/shaderpacks/ComplementaryReimagined_*.zip`, `pack/overrides/options.txt`

**Interfaces:**
- Consumes: semua sistem.

- [ ] **Step 1: Set config inti**

Cold Sweat: suhu awal normal, kerusakan dingin sedang. Thirst Was Taken: laju haus sedang. Zombie Awareness: sensor jarak jauh aktif, door breaking off. Enhanced Visuals: intensitas sedang, efek berhenti 1-2 dtk, hanya damage jarak dekat. KubeJS `cfg` tetap sumber angka gameplay.

- [ ] **Step 2: Shader**

Sertakan zip Complementary Reimagined di `shaderpacks/`. `options.txt`: `renderDistance:8`, `simulationDistance:8`, `entityDistanceScaling:0.75`, `graphicsMode:1`, `maxFps:120`. Preset medium-high dan pengaturan gelap dicatat di README (dipilih manual di menu shader karena file settings dibuat game).

- [ ] **Step 3: Uji**

Server boot dengan config baru tanpa error. Klien: shader bisa dipilih, F3 menunjukkan render/sim 8.

- [ ] **Step 4: Commit**

```bash
git add pack/overrides/config pack/overrides/shaderpacks pack/overrides/options.txt
git commit -m "feat: tuned configs, dark shader, performance profile"
```

---

### Task 13: Build `.mrpack`, README, skrip pindah ke D:

**Files:**
- Create: `tools/build_mrpack.ps1`, `tools/move_instance.ps1`, `README.md`, `dist/ZombieApocalypse-1.0.0.mrpack`

- [ ] **Step 1: Uji gagal**

`build_mrpack.ps1 -DryRun` -> exit 1 bila `tools/mods.lock.json` atau `pack/overrides/` tidak lengkap.

- [ ] **Step 2: Implementasi build**

Zip berisi `modrinth.index.json` (`formatVersion: 1`, `game: "minecraft"`, `versionId: "1.0.0"`, `name`, `files[]` dengan `path: "mods/<file>"`, `hashes.sha1`, `hashes.sha512`, `downloads`, `env` dari `side`) + folder `overrides/` (config, kubejs, shaderpacks, options.txt). Mod manual TIDAK dimasukkan.

- [ ] **Step 3: Verifikasi artefak**

```
powershell -File tools/build_mrpack.ps1
"C:\Users\Random\AppData\Local\Python\pythoncore-3.14-64\python.exe" -c "import zipfile,json;z=zipfile.ZipFile('dist/ZombieApocalypse-1.0.0.mrpack');n=z.namelist();d=json.loads(z.read('modrinth.index.json'));print(len(d['files']),len(n),'overrides/kubejs/server_scripts/30_horde.js' in n)"
```
Expected: `38 <jumlah entry> True`, dan setiap path di `files` ada di `tools/mods.lock.json`.

- [ ] **Step 4: README + skrip pindah**

README: import `.mrpack`, taruh 3 jar manual ke `mods/`, alokasi RAM 8G, pilih shader, pregen Chunky (radius 1000-1500), pindah instance ke `D:\MinecraftPacks\ZombieApocalypse`, troubleshooting (log KubeJS, konflik shader). `move_instance.ps1` menyalin instance ke D: lalu memverifikasi jumlah file dan ruang bebas; tidak menghapus sumbernya.

- [ ] **Step 5: Commit**

```bash
git add tools/build_mrpack.ps1 tools/move_instance.ps1 README.md
git commit -m "feat: mrpack build, install docs, move-to-D script"
```

---

### Task 14: Playtest dan kalibrasi

**Files:**
- Create: `docs/playtest-checklist.md`

- [ ] **Step 1: Checklist manual klien**

Baris dengan hasil yang bisa diamati: dunia baru bersalju tanpa desa; kit muncul sekali saja; bed normal bisa dipakai, bed saat horde ditolak dengan pesan; horde hari 10 datang 3 gelombang, cap 40, hilang saat fajar; zombie hari 3 berarmor, hari 7 pickaxe/axe, hari 12 teleport, hari 30 mutant lebih besar; guard muncul sekali per chest; keempat resep bisa dikerjakan; quest book terbuka dan chapter pertama bisa diselesaikan; visual darah muncul saat kena hit dan memudar.

- [ ] **Step 2: Ukur performa**

Di tengah horde: F3, catat FPS dan jumlah entitas. Syarat: >=45 FPS, entitas <=40. Bila gagal: turunkan `cfg.horde.cap` atau naikkan `cfg.horde.waveDelay`, ulangi uji.

- [ ] **Step 3: Kalibrasi**

Semua angka di satu tempat (`cfg` di `00_util.js`) dan config toml. Catat nilai final di checklist.

- [ ] **Step 4: Commit**

```bash
git add docs/playtest-checklist.md pack/overrides/kubejs/server_scripts/00_util.js
git commit -m "docs: playtest checklist and tuned gameplay constants"
```
