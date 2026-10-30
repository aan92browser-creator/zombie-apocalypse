# Desain Modpack: Zombie Apocalypse Salju (Forge 1.20.1)

Tanggal: 2026-10-30
Status: menunggu persetujuan

## 1. Intent

Pack survival apokaliptik zombie di dunia yang seluruhnya dingin/bersalju.
Player bertahan hidup dengan **eksplorasi dan loot**, bukan bertani atau
membangun mesin. Tiga tekanan: lingkungan (suhu dan kehausan), horde
terjadwal tiap 10 hari, dan zombie yang makin berbahaya seiring hari.

Dibangun untuk dimainkan solo di PC saat ini (Ryzen 5 5600, RX 9060 XT 16GB,
16GB RAM), instance di drive D: (HDD).

## 2. Goals

- Dunia seluruhnya bersalju, dengan kabut, salju menumpuk, dan shader gelap
  yang tetap terbaca.
- Suhu + kehausan aktif; wool penting karena armor berlapis wool menghangatkan.
- Senjata api beragam, amunisi mudah dibuat.
- Horde tiap 10 hari, sleep lock saat horde, kesulitan naik tiap siklus.
- Zombie makin pintar: armor, senjata jarak dekat, varian ender pearl
  (teleport), pickaxe (hancurkan batu), axe (hancurkan kayu).
- Mutant muncul mulai hari 30 dengan peluang naik tiap hari.
- Reruntuhan berisi loot, sebagian dijaga zombie.
- Questline pemandu survival.
- Starter kit saat pertama spawn.
- 60 FPS di luar horde, minimal 45 FPS saat horde, 1080p shader medium-high.

## 3. Non-goals

- Bukan kitchen-sink; target ~41 mod.
- Tanpa mod tech/magic/pertanian otomatis, tanpa dimension tambahan.
- Bukan pitch black.
- Tidak dioptimalkan untuk multiplayer.
- Tanpa mod Java custom.

## 4. Anti-goals

- Player tidak bisa melihat zombie yang mendekat.
- Horde bikin lag parah.
- Mekanik khas hanya "mirip" karena memakai mod jadi apa adanya.
- Player grinding amunisi, bukan eksplorasi.
- Masih ada biome hijau/panas.

## 5. Constraints dan keputusan yang sudah diputuskan

| Topik | Keputusan |
|---|---|
| Versi | Minecraft 1.20.1, Forge 47.x |
| Launcher | Modrinth App, deliverable `.mrpack` + overrides |
| Mode | Solo, RAM MC 8GB |
| Lokasi | `D:\MinecraftPacks\ZombieApocalypse` (HDD) |
| Tidur | Boleh di malam biasa; dimalam horde bed dikunci sejak tick 12000 |
| Musuh lain | Zombie saja; skeleton/creeper/spider/pillager dimatikan; Nether & End dikunci |
| Gunpowder | Dari loot struktur + resep KubeJS (charcoal + flint + sand) |
| Dunia | Struktur tersebar (bukan Lost Cities); desa vanilla dimatikan |
| Bahasa | Quest, pesan, tooltip: Indonesia; nama item/senjata: English |
| Suhu | Cold Sweat |
| Kehausan | Thirst Was Taken (Forge 1.20.1) |
| Quest | FTB Quests + FTB Library + FTB Teams (manual dari CurseForge) |
| Performa | 60 FPS normal, >=45 saat horde, cap 40 zombie |

## 6. Pendekatan yang dipertimbangkan

1. Rakit mod jadi + config saja — tidak bisa mewujudkan mekanik khas.
2. **Hybrid: mod + KubeJS + datapack. DIPILIH.** Mod untuk sistem berat,
   KubeJS untuk aturan khas, datapack untuk dunia. Tanpa compile Java.
3. Mod custom penuh (Java) — butuh toolchain, waktu jauh lebih lama.

## 7. Arsitektur

### 7.1 Pembagian tanggung jawab

| Lapisan | Menangani |
|---|---|
| Mod | suhu, kehausan, sensor zombie, senjata api, quest, performa, shader, struktur, atmosfer |
| KubeJS | spawn control, horde, sleep lock, mutant, role zombie, guard struktur, starter kit, resep, armor wool |
| Datapack | biome dingin, penghapusan desa, dimensi terkunci, loot table struktur |

**Satu otoritas saja.** Improved Mobs, The Hordes, dan Lost Cities tidak
dipakai. Perlengkapan, skala kesulitan, dan penghancuran blok zombie
sepenuhnya milik KubeJS; Zombie Awareness hanya memberi sensor jarak jauh
(door breaking dimatikan di config).

### 7.2 Daftar mod (~41)

| Kategori | Mod |
|---|---|
| Performa | Embeddium, Oculus, ModernFix, FerriteCore, EntityCulling, Canary, Clumps, AI Improvements, MemoryLeakFix |
| Survival | Cold Sweat + GlitchCore, Thirst Was Taken, Zombie Awareness |
| Tempur | TaCZ (Timeless and Classics Zero) |
| Quest | FTB Quests, FTB Library, FTB Teams (manual) |
| Skrip | KubeJS, Rhino, Architectury API, OpenLoader (memuat datapack pack-wide) |
| Struktur | When Dungeons Arise, Structory, Structory: Towers, YUNG's Better Dungeons + YUNG's API, Additional Structures |
| Salju | Snow! Real Magic!, Snow Under Trees |
| Loot/QoL | Sophisticated Backpacks + Core, Corpse, Jade, AppleSkin, Waystones |
| Atmosfer & feedback | AmbientSounds, Sound Physics Remastered, Enhanced Visuals |
| Opsional | Pehkui (skala mutant), Chunky (pregen) |

Shader (file): Complementary Reimagined, preset medium-high; malam lebih
gelap, kabut lebih tebal, efek mahal dimatikan bila FPS turun.

### 7.3 Dunia salju (datapack)

- Sumber data: JSON biome vanilla 1.20.1 diekstrak dari data resmi, lalu
  digenerate ulang oleh skrip dengan `temperature` disetel -0.5..0.1
  (variasi regional: semakin tinggi/terpencil semakin dingin),
  `precipitation: snow`, warna langit/kabut/air/rumput disetel ke palet dingin.
- Tipe biome tetap dipertahankan (gurun, jungle, dll. tetap ada sebagai
  versi membeku) supaya struktur yang bergantung pada biome tidak hilang.
- Desa vanilla dihapus dari structure set; struktur mod tetap ada.
- Snow! Real Magic! + Snow Under Trees menangani akumulasi salju.
- Tidak memakai mod biome pihak ketiga.

### 7.4 Kehausan dan air di dunia beku

- Thirst Was Taken memberi bar hidrasi, botol air, dan purified water.
- Karena semua air permukaan membeku, air didapat dari: salju/ice + botol
  (resep KubeJS), ice di dekat sumber panas, dan loot struktur.
- Purified water mengikuti mekanik Thirst Was Taken (perebusan).
- Botol air masuk starter kit dan loot untuk menjaga early game tidak buntu.

### 7.5 Suhu dan armor wool

- Cold Sweat mengatur suhu tubuh dari biome, ketinggian, cuaca, waktu,
  kebasahan, dan sumber panas (api unggun, lava, pakaian).
- Item baru via KubeJS: **Insulated Leather Armor** (helmet/chest/legs/boots),
  craft dari leather armor + 2 wool per bagian. Memberi armor setara kulit
  plus nilai insulasi Cold Sweat; tooltip menampilkan status menghangatkan.
- Fallback bila KubeJS tidak bisa mendaftarkan tipe armor: item `basic` +
  attribute `generic.armor`/`generic.armor_toughness` + efek hangat berbasis
  tick KubeJS.

### 7.6 Horde (KubeJS)

- Hari horde: day % 10 == 0 (10, 20, 30, ...).
- Mulai senja (13000), gelombang di 14000/16000/18000, selesai fajar (23000);
  sisa zombie di-discard.
- Sleep lock aktif sejak tick 12000 di hari horde (menutup celah tidur
  pukul 12542-13000).
- Jumlah: `8 + 4 * (hordeIndex - 1)` per gelombang, cap 40 total, spawn
  bertahap di ring 32-48 blok.
- Perlengkapan dan atribut naik per siklus horde; gelombang malam horde
  selalu memakai tier perlengkapan hari itu.
- Tidur di malam biasa tetap boleh; tidur tidak memulihkan haus/suhu.

### 7.7 Eskalasi zombie harian

| Hari | Yang muncul |
|---|---|
| 1-2 | zombie dasar |
| 3+ | armor kulit/chain + senjata jarak dekat |
| 7+ | zombie pickaxe (batu/ore), zombie axe (kayu) |
| 12+ | zombie ender pearl (teleport, cooldown 8 dtk, radius 16) |
| 20+ | armor besi, senjata lebih kuat |
| 30+ | mutant: chance `min(0.03 + 0.004*(hari-30), 0.30)` |

Mutant: HP 3-4x, damage naik, knockback resistance, skala 1.4x (Pehkui bila
tersedia), boleh membawa role tambahan.

Aturan penghancuran blok: whitelist batu/ore untuk pickaxe, log/plank untuk
axe. Rate limit 1 blok per 3 detik per zombie, hanya saat mengejar player
dalam 8 blok, dan tidak pernah di dekat spawn point player (radius 16 blok)
kecuali saat horde. Saat horde rate limit jadi 1,5 detik supaya dinding base
punya arti.

### 7.8 Spawn control dan dimensi

- KubeJS membatalkan spawn semua hostile selain zombie; spawn rate zombie
  dinaikkan ringan di malam hari.
- Nether: aktivasi portal dibatalkan (interaksi flint & steel / portal frame).
- End: eye of ender tidak bisa dipasang; stronghold tetap ada sebagai loot.
- Fallback bila blokir portal tidak andal: portal tetap bisa dibuat tetapi
  Nether/End tidak memiliki spawn hostile dan tidak punya loot kunci.

### 7.9 Guard struktur dan loot

- Saat chest loot struktur pertama kali dibuka, 2-4 zombie spawn di sekitar,
  diskalakan sesuai hari. Posisi dicatat di persistent data (maks 500 entri).
- Loot table struktur ditambah: amunisi, makanan, botol air, material armor,
  jarang senjata api.
- Backpack: Sophisticated Backpacks (craft dari kulit + wool, upgrade dari
  loot) untuk menampung hasil eksplorasi; sengaja tidak masuk starter kit
  supaya awal permainan tetap berat.
- Waystones di-set sparse; hanya muncul di reruntuhan besar.

### 7.10 Starter kit (join pertama)

- Full Insulated Leather Armor
- 1 pistol TaCZ + 64 peluru
- 8 cooked beef + 4 water bottle
- 8 obor

### 7.11 Questline (FTB Quests, teks Indonesia)

Hari Pertama (kit, amunisi, shelter) -> Dingin (wool, armor insulated, api
unggun) -> Haus (sumber air, purified water) -> Senjata (loot struktur) ->
Malam ke-10 (selamat dari horde) -> Benteng (dinding, trap, horde ke-2) ->
Mutasi (bunuh mutant). Reward: amunisi, makanan, air, material.

### 7.12 Umpan balik visual saat terkena hit

- Enhanced Visuals: cipratan darah di layar, vignette merah, dan getaran
  kamera saat player menerima damage dari zombie; partikel darah di sekitar
  luka.
- Di-set hanya untuk damage jarak dekat zombie, dengan intensitas sedang:
  layar tidak pernah tertutup penuh agar player tetap bisa melihat dan
  bereaksi.
- Efek memudar cepat (1-2 detik) dan tidak menumpuk saat kena hit beruntun.
- Ada opsi mematikan/mengurangi efek lewat config untuk kenyamanan
  (motion sickness); README mencantumkan caranya.
- Biaya performa rendah (overlay + partikel), tidak memengaruhi FPS horde.

### 7.13 Profil performa

- Alokasi 8GB, render 8-10, simulation 8, entity distance ~75%.
- Shader medium-high 1080p; matikan reflection/volumetric bila perlu.
- Cap 40 zombie, spawn staggered, despawn saat fajar.
- Chunky opsional untuk pregen radius 1000-1500 blok sebelum main (mengurangi
  stutter HDD).
- Pemeriksaan KubeJS per 10 tick dengan selector berbasis tag, bukan scan
  seluruh entitas.

## 8. Deliverable

1. `pack/` berisi `.mrpack` (mod Modrinth + overrides: config, KubeJS,
   datapack, shader, world preset) siap import Modrinth App.
2. `manual-mods/` + README: 3 jar FTB (Quests, Library, Teams) versi tepat.
3. README instalasi: import pack, pindah instance ke D:, alokasi RAM,
   setting shader, pregen, troubleshooting.
4. Skrip PowerShell opsional: pindah instance ke D: dan cek ruang.

## 9. Risiko dan mitigasi

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Skema insulasi Cold Sweat tidak cocok untuk item custom | wool-warmth gagal | fallback attribute + tick KubeJS |
| Resep amunisi TaCZ tidak bisa disuntik KubeJS | amunisi sulit | JSON data TaCZ di datapack |
| Blokir portal Nether/End tidak andal | player lolos ke dimensi lain | fallback: dimensi tanpa hostile/loot kunci |
| Horde berat di CPU | lag | cap 40, stagger, despawn, uji beban |
| Zombie merusak dunia sembarangan | griefing | whitelist, radius 8, rate limit, radius aman spawn |
| D: HDD | stutter saat chunk gen | jarak render rendah, pregen Chunky |
| 3 jar CurseForge manual | pack tidak lengkap | README langkah jelas |
| Tidur mempercepat hari | mutant datang lebih cepat dari ekspektasi | horde tetap tidak bisa di-skip; quest pacing disesuaikan |

## 10. Yang diserahkan ke builder

- Versi tepat setiap mod, urutan dependency, dan isi `.mrpack`.
- Struktur folder KubeJS, nama fungsi, nilai config final.
- Generator JSON biome, daftar biome, palet warna.
- Isi questline dan reward.
- Checklist pengujian (spawn, horde, sleep lock, role zombie, guard, shader).
- Kalibrasi angka berdasarkan uji main.
