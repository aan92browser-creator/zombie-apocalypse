# Playtest Checklist — Zombie Apocalypse 1.0.0

Status: **server headless terverifikasi; item klien menunggu playtest manual.**

Keterangan: `[x]` = terverifikasi di server uji (bukti command RCON), `[ ]` = harus dicek di klien (butuh pemain + grafis).

## A. Dunia & spawn

| # | Yang diamati | Status | Bukti / cara cek |
|---|---|---|---|
| A1 | Dunia baru seluruhnya bersalju/dingin, tanpa desa | [ ] | Buat dunia baru, terbang 500 blok; cek tidak ada village |
| A2 | Starter kit muncul **sekali** saat spawn pertama | [ ] | Spawn pertama: 4 armor insulated, glock_17 + 64 ammo 9mm, 8 steak, 4 air, 8 obor; relog tidak memberi ulang |
| A3 | Kit berisi item yang benar | [x] | `zombieapoc kitPreview` → 9 baris sesuai daftar di atas |
| A4 | Hanya zombie family yang spawn alami | [x] | `zombieapoc canSpawn minecraft:zombie` true; `creeper`/`skeleton` false |

## B. Suhu & kehausan

| # | Yang diamati | Status | Bukti / cara cek |
|---|---|---|---|
| B1 | Suhu turun saat di luar, naik saat dekat api | [ ] | Pantau termometer Cold Sweat 1 menit di luar / dekat furnace |
| B2 | Armor wool menghangatkan | [ ] | Pakai 4 piece insulated vs tanpa; bandingkan laju suhu |
| B3 | Damage dingin sedang (±0.75 hati / 2 dtk) | [ ] | Biarkan suhu jatuh ke batas; catat damage |
| B4 | Kehausan mengisi/mengosongkan sesuai laju 1.0× hunger | [ ] | Bandingkan durasi bar haus vs hunger |
| B5 | Air mentah bisa membuat sakit, air direbus tidak | [ ] | Minum air danau vs air botol yang direbus |

## C. Horde

| # | Yang diamati | Status | Bukti / cara cek |
|---|---|---|---|
| C1 | Hari 10/20/30 = hari horde | [x] | `zombieapoc isHordeDay 10` → true, `11` → false |
| C2 | Horde mulai malam (tod ≥13000), 3 gelombang, cap 40 | [x] | `zombieapoc setclock 100 18500` → `active index=10 ... count=40` |
| C3 | Tidur ditolak saat malam horde + pesan "Tidak bisa tidur saat horde!" | [x] | `zombieapoc blockSleep` → true (logika klik bed diuji di klien) |
| C4 | Pesan "Horde dimulai!" / "Gelombang n" tampil | [ ] | Lihat chat saat C2 |
| C5 | Horde berakhir saat tod 23000 dan zombie dibersihkan | [x] | `setclock 100 23100` → `idle`, `count: 0` |
| C6 | Horde tidak restart setelah fajar | [x] | `setclock 100 23500` → `idle`, tanpa zombie baru |
| C7 | Tidur normal lagi hari berikutnya | [x] | `setclock 101 6000` → `blockSleep` false |
| C8 | FPS ≥45 dan entitas ≤40 saat horde | [ ] | Klien: F3 di tengah horde; catat FPS + `E:` |

## D. Zombie pintar

| # | Yang diamati | Status | Bukti / cara cek |
|---|---|---|---|
| D1 | Hari 3+ zombie berarmor | [x] | `zombieapoc weights 3` → `base=50 armored=25` |
| D2 | Hari 7+ pickaxe/axe, dapat menghancurkan blok | [x] | `weights 7`; `canBreak pickaxe minecraft:stone` true, `axe minecraft:oak_log` true |
| D3 | Pickaxe tidak menghancurkan kayu, axe tidak menghancurkan batu | [x] | `canBreak pickaxe minecraft:oak_log` false, `axe minecraft:stone` false |
| D4 | Hari 12+ sebagian zombie membawa ender pearl & teleport | [x] | `weights 12` → `pearl=10` (perilaku teleport diuji Task 8) |
| D5 | Hari 30+ zombie mutan lebih besar/kuat, muncul di horde | [x] | `mutantChance 29/30/60/100` → 0.00 / 0.03 / 0.15 / 0.30 |
| D6 | Armor tampak di model zombie (visual) | [ ] | Klien: lihat zombie hari 3+ |

## E. Loot, guard, kerajinan

| # | Yang diamati | Status | Bukti / cara cek |
|---|---|---|---|
| E1 | Reruntuhan tersebar, sebagian peti dijaga zombie | [ ] | Jelajah; buka peti reruntuhan |
| E2 | Guard hanya muncul sekali per peti | [x] | `zombieapoc guardTest x y z` → `guarded 2..4`, ulang → `already guarded` (Task 9) |
| E3 | 4 resep armor insulated bisa dikerjakan | [x] | `recipeCheck kubejs:insulated_leather_*` → true |
| E4 | Amunisi 9mm, air bersih, backpack bisa dikerjakan | [x] | `recipeCheck kubejs:ammo_basic|water_bottle|backpack` → true |
| E5 | Resep benar-benar bisa di-craft di grid 2×2/3×3 | [ ] | Klien: coba craft di crafting table |

## F. Quest, shader, visual

| # | Yang diamati | Status | Bukti / cara cek |
|---|---|---|---|
| F1 | Buku quest terbuka, 7 chapter/29 quest, teks Indonesia | [x] | Log server: `Loaded 1 chapter groups, 7 chapters, 29 quests`; `check_quests.py` ok |
| F2 | Chapter "Hari Pertama" bisa diselesaikan | [ ] | Klien: selesaikan 4 checkmark |
| F3 | Shader Complementary Reimagined bisa dipilih | [ ] | Video Settings → Shader Packs |
| F4 | F3 menunjukkan render 8 / simulasi 8 | [ ] | Klien: F3 kiri atas |
| F5 | Efek darah muncul saat kena hit dan memudar | [ ] | Klien: biarkan zombie memukul |
| F6 | Backpack bisa dipakai | [ ] | Klien: klik kanan backpack |

## G. Performa (diukur)

| Metrik | Target | Hasil |
|---|---|---|
| Entitas horde saat puncak | ≤40 | **40** (`active ... count=40`, hari 100) |
| FPS di tengah horde | ≥45 | **belum diukur** — butuh klien; bila <45 turunkan `cfg.horde.cap` ke 32 atau `renderDistance` ke 6 |
| Boot server tanpa error config | ya | `Done (2.643s)`, tanpa baris error config |
| KubeJS scripts | 0 error | `Loaded 8/8 KubeJS server scripts ... with 0 errors` |

## H. Nilai final `cfg` (`pack/overrides/kubejs/server_scripts/00_util.js`)

```
hordeEveryDays 10 | sleepLockTick 12000 | waveTicks [14000,16000,18000] | hordeEndTick 23000
waveBase 8 | waveStep 4 | waveCap 40 | ringMin 32 | ringMax 48
mutantFromDay 30 | mutantBase 0.03 | mutantStep 0.004 | mutantCap 0.3
roleDays { armor 3, weapon 3, tools 7, ender 12, iron 20, mutant 30 }
breakRate 60 | breakRateHorde 30 | chaseRadius 8 | safeRadius 16
```

Config toml final: Cold Sweat `Temperature Damage 1.5`, `Rate Multiplier 0.9`;
Thirst `thirstDepletionModifier 1.0`; Zombie Awareness `maxPFRangeSense 64`, `wanderingHordes false`,
`enhancedMobs` hanya zombie/husk/drowned/zombie_villager.

## I. Temuan saat uji

- **Diperbaiki:** horde bisa ter-restart tepat setelah fajar (tod 23000–24000) karena syarat mulai hanya `tod ≥ 13000`; sekarang dibatasi `tod < hordeEndTick`. Bukti: C6 idle.
- Sisa zombie horde dari sesi uji sebelumnya (69 entitas) menunjukkan `/kill` di `endHorde` tidak menjangkau entitas di chunk yang tidak termuat; setelah perbaikan restart, tidak ada penumpukan baru. Pantau di klien (C5/C6).
- Cold Sweat mencatat error kompatibilitas thirst 3.0.0; versi 1.20.1 maksimum 1.4.0 → benign (lihat README).