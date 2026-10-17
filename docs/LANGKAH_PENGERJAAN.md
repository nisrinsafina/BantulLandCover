# Langkah Pengerjaan

Dokumen ini menjelaskan pengerjaan tugas secara berurutan, dari memilih wilayah sampai aplikasi online dan repositori GitHub. Urutannya mengikuti butir-butir pada deskripsi tugas.

## Daftar Isi

0. [Persiapan lingkungan kerja](#0-persiapan-lingkungan-kerja)
1. [Penentuan ROI](#1-penentuan-roi)
2. [Unduh data satelit dan data administrasi](#2-unduh-data-satelit-dan-data-administrasi)
3. [Susun folder proyek](#3-susun-folder-proyek)
4. [Pemotongan citra (cropping)](#4-pemotongan-citra-cropping)
5. [Hitung indeks spektral](#5-hitung-indeks-spektral)
6. [Threshold dan klasifikasi tutupan lahan](#6-threshold-dan-klasifikasi-tutupan-lahan)
7. [Zonal statistics per kecamatan](#7-zonal-statistics-per-kecamatan)
8. [Ekspor hasil untuk web](#8-ekspor-hasil-untuk-web)
9. [Membangun WebGIS Shiny dan Leaflet](#9-membangun-webgis-shiny-dan-leaflet)
10. [Laporan cetak (peta dan tabel)](#10-laporan-cetak-peta-dan-tabel)
11. [Deploy ke shinyapps.io](#11-deploy-ke-shinyappsio)
12. [Mengunggah ke GitHub](#12-mengunggah-ke-github)
13. [Pemetaan butir tugas ke berkas](#13-pemetaan-butir-tugas-ke-berkas)
14. [Masalah umum](#14-masalah-umum)

---

## 0. Persiapan lingkungan kerja

1. Install **R** dari <https://cran.r-project.org/> dan **RStudio** dari <https://posit.co/download/rstudio-desktop/>.
2. Pengguna Windows yang perlu mengompilasi package dari sumber juga memerlukan **Rtools** (<https://cran.r-project.org/bin/windows/Rtools/>). R versi baru mengenali Rtools otomatis.
3. Install package di Console RStudio:

   ```r
   install.packages(c(
     "terra", "sf", "dplyr",
     "shiny", "shinydashboard", "shinyWidgets", "leaflet", "leaflet.extras",
     "DT", "plotly", "png", "jpeg", "maptiles", "htmlwidgets",
     "rstudioapi", "rsconnect"
   ))
   ```

> Modul tugas menyebut `rgdal` dan `raster`. Keduanya sudah tidak dipelihara di CRAN, jadi proyek ini memakai `sf` (vektor) dan `terra` (raster) yang fungsinya setara.

---

## 1. Penentuan ROI

**Wilayah studi: Kabupaten Bantul, D.I. Yogyakarta** (17 kecamatan).

Alasan pemilihan:

- Lanskapnya bergradasi: utara padat permukiman (berbatasan dengan Kota Yogyakarta), tengah dataran aluvial persawahan, timur perbukitan, selatan pesisir Samudra Hindia.
- Keempat kelas tutupan lahan hadir: vegetasi, bangunan, perairan (Sungai Progo, Sungai Opak, laut selatan), dan awan.
- Jumlah kecamatan memadai untuk membandingkan statistik zonal.
- Batas administrasi skala 1:25.000 (RBI) tersedia dari Ina-Geoportal.

---

## 2. Unduh data satelit dan data administrasi

### 2.1 Citra Sentinel-2 Level-2A

1. Buka **Copernicus Data Space Ecosystem** (<https://dataspace.copernicus.eu/>), lalu masuk ke *Copernicus Browser*. Buat akun gratis jika belum punya.
2. Gambar atau cari area **Kabupaten Bantul**.
3. Pilih sumber data **Sentinel-2**, tipe produk **L2A**.
4. Atur rentang tanggal dan **filter tutupan awan (cloud cover)** serendah mungkin.
5. Pilih satu produk yang mencakup seluruh Bantul, lalu unduh.
6. Ekstrak berkas ZIP sampai menjadi folder berakhiran `.SAFE`.

Produk yang dipakai pada proyek ini:

```text
S2B_MSIL2A_20261004T023529_N0513_R089_T49MDM_20261004T075248.SAFE
```

| Bagian nama | Arti |
|---|---|
| `S2B` | Satelit Sentinel-2B |
| `MSIL2A` | Level-2A (sudah terkoreksi atmosfer) |
| `20261004T023529` | Tanggal dan waktu perekaman (4 Oktober 2026, 02:35:29 UTC) |
| `N0513` | Versi pemrosesan |
| `R089` | Orbit relatif |
| `T49MDM` | Tile UTM zona 49 |

### 2.2 Batas administrasi

1. Buka **Ina-Geoportal** BIG (<https://tanahair.indonesia.go.id/portal-web>), masuk atau daftar akun.
2. Cari data **RBI 25K** (Rupabumi Indonesia skala 1:25.000) untuk **Kabupaten Bantul**.
3. Unduh dan ekstrak. Hasilnya berupa geodatabase `2022_RBI25K_KAB_BANTUL_KUGI50_20221231.gdb`.

Layer yang dipakai di script:

| Layer | Fungsi |
|---|---|
| `ADMINISTRASI_AR_KABKOTA` | Batas kabupaten (di-filter `WADMKK == "Bantul"`) |
| `ADMINISTRASI_AR_KECAMATAN` | Batas kecamatan (di-filter `WADMKK == "Bantul"`) |

---

## 3. Susun folder proyek

Susun folder kerja (di luar repositori GitHub) seperti ini. Nama folder harus persis, karena script mencarinya:

```text
Folder/
├── 01_Satellite_Data/
│   └── 20261004/
│       └── S2B_MSIL2A_20261004T023529_N0513_R089_T49MDM_20261004T075248.SAFE/
└── 02_Administration_Data/
    └── Kab Bantul RBI BIG/
        └── 2022_RBI25K_KAB_BANTUL_KUGI50_20221231.gdb/
```

Folder `03_Cropped`, `04_Index`, `05_Classification`, dan `06_WebGIS` dibuat otomatis oleh script.

---

## 4. Pemotongan citra (cropping)

**Berkas:** `analisis/01_ANALISIS_RASTER.R`, bagian `PERSIAPAN` sampai `MEMBACA BAND SENTINEL`.

1. Ubah baris `setwd("...")` ke lokasi folder `Folder` di komputermu.
2. Script membaca batas kabupaten dan kecamatan dari `.gdb`, lalu merapikannya (`st_zm`, `st_make_valid`, ubah ke EPSG:4326, gabungkan poligon dengan nama kecamatan yang sama).
3. Script mencari 6 band di folder `IMG_DATA`:

   | Band | Resolusi | Dipakai untuk |
   |---|:--:|---|
   | B02 (Biru) | 10 m | Penguat deteksi awan |
   | B03 (Hijau) | 10 m | NDWI |
   | B04 (Merah) | 10 m | NDVI, NDCI |
   | B05 (Red Edge) | 20 m | Disertakan dalam hasil crop |
   | B08 (NIR) | 10 m | NDVI, NDBI, NDWI, NDCI |
   | B11 (SWIR) | 20 m | NDBI |

4. Tiap band di-*crop* dengan batas kabupaten, B05 dan B11 di-*resample* ke 10 m, nilai DN diubah menjadi reflektansi memakai `BOA_ADD_OFFSET`, lalu di-*mask* dengan poligon kabupaten.
5. Hasilnya disimpan di `03_Cropped/` (`B02_Cropped.tif` sampai `B11_Cropped.tif`). Pada jalankan berikutnya, script memakai hasil ini agar lebih cepat. Ubah `force_reprocess <- TRUE` untuk memproses ulang.

Cek singkat: nilai reflektansi harus berada di rentang 0 sampai 1, bukan ribuan.

---

## 5. Hitung indeks spektral

**Berkas:** bagian `MENGHITUNG INDEKS`.

```r
ndvi <- nd_index(b8,  b4)   # vegetasi
ndbi <- nd_index(b11, b8)   # area terbangun
ndwi <- nd_index(b3,  b8)   # perairan
ndci <- nd_index(b4,  b8)   # awan
```

Hasil disimpan sebagai `04_Index/NDVI.tif`, `NDBI.tif`, `NDWI.tif`, dan `NDCI.tif`.

---

## 6. Threshold dan klasifikasi tutupan lahan

**Berkas:** bagian `MENENTUKAN THRESHOLD KLASIFIKASI`.

1. Threshold awal ditentukan, lalu dicek lewat histogram (garis merah = threshold):

   | Parameter | Nilai |
   |---|:--:|
   | `thr_ndvi` | 0,30 |
   | `thr_ndbi` | 0,00 |
   | `thr_ndwi` | 0,05 |
   | `thr_ndci` | 0,05 |
   | `thr_biru` (B02) | 0,20 |

2. Klasifikasi berprioritas: **Awan (4) → Perairan (3) → Vegetasi (1) → Bangunan (2)**.
3. Setiap kelas mendapat kode warna sendiri:

   | Kelas | Kode | Warna |
   |---|:--:|:--:|
   | Vegetasi | 1 | `#358221` |
   | Bangunan | 2 | `#ED022A` |
   | Perairan | 3 | `#1A5BAB` |
   | Awan | 4 | `#C8C8C8` |

4. Hasilnya adalah satu peta komposit `05_Classification/klasifikasi_tutupan_lahan_bantul.tif`.

Jika hasil klasifikasi tampak janggal (misalnya terlalu banyak awan), ubah nilai threshold, jalankan ulang bagian ini, dan cocokkan dengan citra warna asli (`plotRGB`).

---

## 7. Zonal statistics per kecamatan

**Berkas:** bagian `ZONAL STATISTICS`.

Untuk setiap kecamatan dan setiap indeks (NDVI, NDBI, NDWI, NDCI), script menghitung **Mean, Min, Max, Median, SD**, ditambah Modus. Hasilnya satu tabel dengan satu baris per kecamatan (`STATS_TABLE`). Script juga menghitung:

- statistik untuk seluruh kabupaten (`STATS_KAB`), dan
- luas tiap kelas tutupan lahan per kecamatan dalam hektar beserta kelas dominannya (`LC_AREA`).

---

## 8. Ekspor hasil untuk web

**Berkas:** bagian `EKSPOR HASIL UNTUK WEB`. Hasilnya di `06_WebGIS/`:

| Berkas | Isi |
|---|---|
| `zonal_statistics_kecamatan.csv` | Tabel zonal statistics (untuk laporan 6.2) |
| `statistik_kabupaten.csv` | Statistik tingkat kabupaten |
| `luas_tutupan_lahan_kecamatan.csv` | Luas kelas per kecamatan |
| `threshold_klasifikasi.csv` | Parameter threshold |
| `hasil_analisis.gpkg` | Batas kabupaten dan kecamatan + atribut statistik |
| `hasil_analisis.rds` | Metadata yang dibaca aplikasi web |

Setelah itu, jalankan `scripts/siapkan_data_deploy.R` untuk menyalin semua hasil ke folder `data_deploy/` (data untuk aplikasi) dan `output/` (tabel CSV untuk dokumentasi).

---

## 9. Membangun WebGIS Shiny dan Leaflet

**Berkas:** `app.R`.

Struktur dasar aplikasi mengikuti modul tutorial:

```r
ui <- dashboardPage(
  dashboardHeader(),
  dashboardSidebar(),
  dashboardBody()
)
server <- function(input, output, session) { }
shinyApp(ui, server)
```

Pada proyek ini kerangka tersebut dikembangkan menjadi enam tab (Peta Interaktif, Zonal Statistics, Threshold dan Metode, Cetak Peta, Unduh Data, Tentang). Rincian fitur ada di [README](../README.md#fitur-webgis).

Cara menjalankan:

1. Buka `app.R` di RStudio.
2. Klik **Run App** (centang *Run External* agar terbuka di browser).
3. Aplikasi mendeteksi folder `data_deploy/` secara otomatis, sehingga tidak perlu mengubah path.

---

## 10. Laporan cetak (peta dan tabel)

### 6.1 Peta komposit klasifikasi

1. Buka tab **Cetak Peta** di aplikasi.
2. Centang layer **Tutupan Lahan** dan batas kabupaten atau kecamatan.
3. Isi judul peta, pilih kertas (A3 atau A4), format (PDF disarankan untuk cetak), dan resolusi.
4. Klik **Perbarui pratinjau**, lalu **Unduh Peta**.

Peta cetak otomatis memuat: judul, legenda 4 kelas, **skala**, **panah utara**, grid koordinat UTM, inset lokasi, sumber data, serta identitas pembuat dan dosen.

### 6.2 Tabel zonal statistics

- Buka tab **Zonal Statistics**, lalu salin atau ekspor tabel ke Excel (tombol di atas tabel), atau
- gunakan langsung `output/zonal_statistics_kecamatan.csv`, lalu rapikan di Word atau Excel sesuai format laporan.

---

## 11. Deploy ke shinyapps.io

1. Daftar gratis di <https://www.shinyapps.io>. **Username** yang dipilih akan menjadi bagian link aplikasi.
2. Buka **Account → Tokens → Show**, lalu salin nilai `name`, `token`, dan `secret`.
3. Buka `scripts/deploy_shinyapps.R`, isi ketiga nilai tersebut, lalu jalankan.
4. Tunggu 5 sampai 15 menit. Setelah selesai, link aplikasi terbuka otomatis dengan format:

   ```text
   https://USERNAME.shinyapps.io/NAMA-APLIKASI/
   ```

5. Salin link tersebut ke `README.md` dan `CITATION.cff` (ganti `GANTI-USERNAME` dan `GANTI-NAMA-APP`).

> **Penting:** jangan pernah meng-commit `token` dan `secret` ke GitHub. Hapus nilainya dari `deploy_shinyapps.R` sebelum `git commit`, atau simpan hanya di komputermu.

---

## 12. Mengunggah ke GitHub

Urutan singkat setelah file siap (jalankan di Terminal RStudio pada folder repositori):

```bash
git status                    # lihat file yang berubah
git add .                     # tandai semua perubahan
git commit -m "Lengkapi dokumentasi dan struktur repositori"
git push                      # kirim ke GitHub
```

Setelah itu atur halaman repositori di GitHub:

1. Klik ikon ⚙️ di sebelah **About** pada halaman utama.
2. Isi *Description*, *Website* (link aplikasi), dan *Topics* (misalnya `r`, `shiny`, `leaflet`, `sentinel-2`, `remote-sensing`, `webgis`, `land-cover`, `ndvi`, `bantul`).

---

## 13. Pemetaan butir tugas ke berkas

| Butir tugas | Dikerjakan di | Hasil |
|---|---|---|
| 1. Penentuan ROI + alasan | [Bagian 1](#1-penentuan-roi), [README](../README.md#wilayah-studi) | Kabupaten Bantul |
| 2.1 Unduh Sentinel-2 L2A | [Bagian 2.1](#21-citra-sentinel-2-level-2a) | Folder `.SAFE` (tidak di-commit) |
| 2.2 Unduh batas administrasi | [Bagian 2.2](#22-batas-administrasi) | Geodatabase `.gdb` (tidak di-commit) |
| 3. Cropping citra | `analisis/01_ANALISIS_RASTER.R` (bagian *Membaca Band Sentinel*) | `03_Cropped/*.tif` |
| 4.1 Hitung indeks | `analisis/01_ANALISIS_RASTER.R` (*Menghitung Indeks*) | `data_deploy/NDVI.tif`, `NDBI.tif`, `NDWI.tif`, `NDCI.tif` |
| 4.2 Threshold | `analisis/01_ANALISIS_RASTER.R` (*Menentukan Threshold*) | `output/threshold_klasifikasi.csv` |
| 4.3 Peta komposit 4 kelas | `analisis/01_ANALISIS_RASTER.R` | `data_deploy/klasifikasi_tutupan_lahan_bantul.tif` |
| 4.4 Kode warna tiap kelas | Tabel `LC` pada script | Hijau, merah, biru, abu-abu |
| 5. Zonal statistics | `analisis/01_ANALISIS_RASTER.R` (*Zonal Statistics*) | `output/zonal_statistics_kecamatan.csv` |
| 6.1 Peta cetak (legenda, skala, panah utara, judul, sumber) | `app.R`, tab **Cetak Peta** | PDF atau PNG hasil unduhan |
| 6.2 Tabel zonal statistics | `app.R`, tab **Zonal Statistics** | Tabel CSV atau Excel |
| WebGIS Shiny + Leaflet | `app.R` | Aplikasi di shinyapps.io |
| Repositori GitHub | Repositori ini | README, dokumentasi, lisensi |

---

## 14. Masalah umum

| Gejala | Penyebab dan solusi |
|---|---|
| `Band tidak ditemukan` | Path `dir_sentinel` salah atau folder `.SAFE` belum diekstrak. Periksa nama folder tanggal dan nama `.SAFE`. |
| `File ditemukan lebih dari satu` | Ada dua produk Sentinel di folder yang sama. Sisakan satu produk. |
| Error `PROJ` atau `GDAL` | Baris `Sys.unsetenv(c("PROJ_LIB", "PROJ_DATA", "GDAL_DATA"))` di awal script sudah menangani sebagian besar kasus. Restart R lalu jalankan lagi. |
| Tab Threshold: histogram kosong | `SAMPLES` belum disimpan ke `hasil_analisis.rds`. Tambahkan sampel piksel ke daftar `saveRDS` di script 01, lalu jalankan ulang. |
| Aplikasi menampilkan "Raster belum berhasil dimuat" | Isi `data_deploy/` belum lengkap. Pastikan 7 berkas utama ada (lihat [README](../README.md#struktur-repositori)). |
| Deploy gagal: package tidak ditemukan | Pastikan `dependencies.R` ikut di-deploy dan semua nama package benar. |
| Aplikasi online berhenti sendiri | Memori paket gratis habis. Perkecil `MAX_CELL_TAMPIL` di `app.R`. |
| `git push` ditolak karena berkas terlalu besar | GitHub membatasi 100 MB per berkas. Pastikan data mentah (`.SAFE`, `.jp2`, `.gdb`) tidak ikut ter-commit (lihat `.gitignore`). |
