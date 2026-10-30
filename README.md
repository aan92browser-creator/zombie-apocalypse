# Zombie Apocalypse — Modpack Survival Salju (Forge 1.20.1)

Pack bertahan hidup di dunia yang seluruhnya dingin: suhu tubuh, kehausan, gerombolan zombie tiap 10 hari, zombie makin pintar dan bermutasi seiring hari, senjata api, reruntuhan berisi loot, dan quest berbahasa Indonesia.

- Minecraft **1.20.1** + **Forge 47.3.0**
- Launcher: **Modrinth App** (file `.mrpack`)
- 41 mod (33 server+klien, 8 khusus klien) + 3 jar manual FTB
- Quest: FTB Quests, 7 chapter / 29 quest

## 1. Instalasi

1. Buka **Modrinth App** → **Create instance** → **Import from file** → pilih `dist/ZombieApocalypse-1.0.0.mrpack`.
2. Buka folder instance (tombol **Folder** di Modrinth App), lalu salin **3 jar manual** ke folder `mods/`:
   - `ftb-quests-forge-2001.4.22.jar`
   - `ftb-library-forge-2001.2.13.jar`
   - `ftb-teams-forge-2001.3.2.jar`
3. Alokasi RAM **8G** (instance → Settings → Java memory). Jangan lebih dari 8G pada PC 16G.
4. Jalankan game sekali, lalu tutup. Game akan membuat `options.txt` lengkap dari profil yang sudah disertakan.

Sumber jar FTB, versi minimum dependensi, dan SHA-256 ada di [`pack/manual-mods/README.md`](pack/manual-mods/README.md). Jar tidak dimasukkan ke `.mrpack` karena lisensi All Rights Reserved.

## 2. Pindah instance ke drive D:

```
powershell -File tools/move_instance.ps1 -Source "C:\path\ke\instance" -Dest "D:\MinecraftPacks\ZombieApocalypse"
```

Skrip menyalin seluruh instance, memverifikasi jumlah file dan ruang bebas (butuh ukuran instance + 1 GB), dan **tidak menghapus sumber**. Setelah itu buka instance dari lokasi baru di Modrinth App.

## 3. Shader (gelap & mencekam)

`shaderpacks/ComplementaryReimagined_r5.9.3.zip` sudah disertakan.

1. Options → Video Settings → Shader Packs → pilih **Complementary Reimagined**.
2. Di menu shader pilih preset **Medium** (atau High bila FPS masih nyaman), lalu sesuaikan:
   - **Lighting → Ambient Light**: matikan (lebih gelap)
   - **Atmospheric → Fog Density / Fog Distance**: naikkan sedikit agar suasana berkabut
   - **Color → Saturation**: turunkan (~0.8) untuk nuansa muram
   - **Shadows**: kualitas Medium, jarak pendek

Preset tidak bisa dikirim lewat file karena `shaders/settings` dibuat oleh game saat pertama kali shader dipilih.

## 4. Profil performa

`options.txt` bawaan pack sudah disetel untuk PC rendah:

| Setting | Nilai |
|---|---|
| renderDistance | 8 |
| simulationDistance | 8 |
| entityDistanceScaling | 0.75 |
| graphicsMode | 1 (Fast) |
| maxFps | 120 |

Gameplay sudah diringankan: horde dibatasi dan tersebar, zombie Awareness hanya meng-enhance zombie family, dan mob non-zombie tidak di-spawn.

## 5. Chunk pre-generation (Chunky)

Jalankan sekali sebelum main supaya tidak ada lag saat berjalan:

```
/chunky radius 1000
/chunky start
```

Radius **1000** untuk PC lemah, **1500** bila masih nyaman. Kembali ke spawn setelah selesai (`/chunky cancel` untuk membatalkan).

## 6. Cara main singkat

- **Hari Pertama**: ikuti chapter quest pertama; starter kit (leather hangat, 1 pistol, 1 stack ammo, makanan) diberikan sekali saat spawn pertama.
- **Dingin**: pakai armor yang sudah diinsulasi wool (dibuat dari leather armor + wool). Pantau termometer.
- **Haus**: minum air bersih (rebus/filter); air mentah bisa membuat sakit.
- **Senjata**: amunisi 9mm dibuat mudah di crafting table (8 butir per craft).
- **Hari ke-10, 20, 30, …**: horde menyerang saat malam dan **tidur dikunci** selama horde. Kesulitan naik tiap horde.
- **Hari ke-30+**: zombie mutan muncul di horde; peluangnya naik seiring hari.
- **Reruntuhan**: tersebar di dunia; sebagian peti dijaga zombie. Zombie juga membawa armor, senjata melee, ender pearl (teleport), pickaxe (menghancurkan batu), dan axe (menghancurkan kayu).

Quest & pesan dalam bahasa Indonesia. Nether dan End dikunci.

## 7. Troubleshooting

- **Quest tidak muncul**: pastikan 3 jar FTB ada di `mods/`; cek log `latest.log` untuk baris `Loaded 1 chapter groups, 7 chapters, 29 quests`.
- **Game crash saat start**: biasanya jar manual belum disalin atau versi Forge salah (harus 47.3.0). Cek `crash-reports/`.
- **Shader hitam/aneh dengan mod lain**: matikan shader dulu untuk memastikan bukan konflik; turunkan preset ke Low.
- **FPS rendah**: turunkan render distance ke 6, matikan shader sementara, dan pastikan Chunky pregen sudah selesai.
- **Log KubeJS**: cari `kubejs/server_scripts` di `logs/latest.log`; baris `Loaded 8/8 KubeJS server scripts ... with 0 errors` berarti normal.
- **Pesan `Cold Sweat requires thirst 1.20.1-3.0.0 or higher`**: benign. Versi Thirst Was Taken terbaru untuk 1.20.1 adalah 1.4.0, jadi modul kompatibilitas suhu air Cold Sweat memang nonaktif; mekanik dingin/haus utama tetap berjalan.
- **Enhanced Visuals**: efek hanya berasal dari damage jarak dekat (semua zombie melee) dan intensitasnya tidak punya config — perilaku bawaan mod.

## 8. Build ulang pack

```
powershell -File tools/fetch_mods.ps1            # unduh/cek pakai lock pinned + verifikasi sha1
powershell -File tools/fetch_mods.ps1 -Update    # resolve ulang versi dari Modrinth lalu tulis lock
powershell -File tools/build_mrpack.ps1 -DryRun   # cek lock + overrides + hash jar
powershell -File tools/build_mrpack.ps1           # hasil: dist/ZombieApocalypse-1.0.0.mrpack
```

Verifikasi: `powershell -File tools/server_test/test_task13.ps1`.