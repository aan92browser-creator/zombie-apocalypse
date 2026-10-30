# Mod manual (FTB)

Tiga mod FTB tidak tersedia di Modrinth, jadi diunduh manual dari CurseForge
(build resmi FTB) dan diletakkan di folder ini. Jar **tidak** ikut di-commit
(lihat `.gitignore`) karena lisensi All Rights Reserved dan ukurannya.

| File | Mod | Versi | Minecraft | Loader |
| --- | --- | --- | --- | --- |
| `ftb-quests-forge-2001.4.22.jar` | FTB Quests | 2001.4.22 | 1.20.1 | Forge |
| `ftb-library-forge-2001.2.13.jar` | FTB Library | 2001.2.13 | 1.20.1 | Forge |
| `ftb-teams-forge-2001.3.2.jar` | FTB Teams | 2001.3.2 | 1.20.1 | Forge |

SHA-256:

```
9ea9d159a78a2724cfe0457b024680fdb52a2126eff9cfa5280a30578f647a68  ftb-quests-forge-2001.4.22.jar
41810281b65336265cae2c88412022d02f2f0a3f28c66a06173d86f98acf14a7  ftb-library-forge-2001.2.13.jar
b1cb4d82ea9f137a87e12a7aaf3329619294b56f7d70337dfd557a76e10b6e07  ftb-teams-forge-2001.3.2.jar
```

## Cara mengunduh

1. Buka CurseForge, cari proyek **FTB Quests (Forge)**, **FTB Library (Forge)**,
   dan **FTB Teams (Forge)**. Pilih tab Files, filter game version `1.20.1`
   dan loader `Forge`, lalu unduh versi pada tabel di atas.
2. Alternatif resmi FTB (dipakai saat pengujian Task 11):

   ```
   https://maven.ftb.dev/releases/dev/ftb/mods/ftb-quests-forge/2001.4.22/ftb-quests-forge-2001.4.22.jar
   https://maven.ftb.dev/releases/dev/ftb/mods/ftb-library-forge/2001.2.13/ftb-library-forge-2001.2.13.jar
   https://maven.ftb.dev/releases/dev/ftb/mods/ftb-teams-forge/2001.3.2/ftb-teams-forge-2001.3.2.jar
   ```

3. Simpan ketiga jar di folder ini (`pack/manual-mods/`) dan verifikasi hash.
   Server uji menyalinnya otomatis ke `server/mods/` lewat `tools/server_test/setup.ps1`.

## Memasang di instance Modrinth App

1. Import `dist/zombie-apocalypse-*.mrpack` ke Modrinth App.
2. Salin ketiga jar dari folder ini ke folder `mods/` instance
   (`<instance>/mods/`).
3. Pastikan **Architectury API** sudah ada dari modpack (dependensi wajib
   FTB Quests dan FTB Library).
4. Jalankan game; buku quest (`ftbquests:book`) ada di kit awal dan bisa
   dibuka dengan klik kanan.

Catatan versi: FTB Quests 1.20.1 membutuhkan FTB Library >= 2001.2.1 dan
FTB Teams >= 2001.1.4. Jangan menaikkan hanya salah satu jar.
