# Riwayat Perubahan

Semua perubahan penting pada proyek ini dicatat di berkas ini.
Format mengikuti [Keep a Changelog](https://keepachangelog.com/id-ID/1.1.0/).

## [1.0.0] - 2026-10-17

### Ditambahkan
- **Analisis raster** (`analisis/01_ANALISIS_RASTER.R`):
  - Crop citra Sentinel-2B L2A (tile T49MDM, 4 Oktober 2026) dengan batas Kabupaten Bantul.
  - Konversi DN ke reflektansi memakai `BOA_ADD_OFFSET`, resample B05 dan B11 ke 10 m.
  - Perhitungan NDVI, NDBI, NDWI, dan NDCI (NDCI = (B04 − B08) / (B04 + B08)).
  - Klasifikasi tutupan lahan empat kelas dengan prioritas Awan > Perairan > Vegetasi > Bangunan.
  - Zonal statistics (Mean, Min, Max, Median, SD, Modus) untuk 17 kecamatan, statistik kabupaten, dan luas tiap kelas.
- **Aplikasi WebGIS** (`app.R`) dengan enam tab: Peta Interaktif, Zonal Statistics, Threshold dan Metode, Cetak Peta, Unduh Data, Tentang.
- **Peta cetak** A3 atau A4 (PNG, PDF, JPEG) dengan legenda, skala, panah utara, grid UTM, inset, judul, dan sumber data.
- **Unduh data**: raster GeoTIFF (UTM atau WGS 84) dan vektor GeoPackage.
- `dependencies.R` agar shinyapps.io mengenali seluruh package.
- Data siap pakai di `data_deploy/` sehingga aplikasi bisa dijalankan tanpa data mentah.
- Script bantu `scripts/siapkan_data_deploy.R` dan `scripts/deploy_shinyapps.R`.
- Dokumentasi: `README.md`, `docs/LANGKAH_PENGERJAAN.md`, `CITATION.cff`, `LICENSE` (MIT).
- Tabel hasil dalam format CSV di folder `output/`.

### Diketahui
- Threshold klasifikasi bersifat empiris dan belum divalidasi dengan data lapangan.
- Kelas "bangunan" adalah kelas sisa, sehingga lahan terbuka dapat ikut terhitung.
