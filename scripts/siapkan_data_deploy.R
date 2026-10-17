# =============================================================================
# SIAPKAN DATA DEPLOY
# Menyalin hasil analisis (dari 01_ANALISIS_RASTER.R) ke folder repositori:
#   - data_deploy/ : data yang dibaca aplikasi (app.R)
#   - output/      : tabel CSV untuk laporan dan dokumentasi
#
# Jalankan SETELAH 01_ANALISIS_RASTER.R selesai.
# =============================================================================

# --- UBAH DUA BARIS INI ------------------------------------------------------
# Folder kerja analisis (tempat 04_Index, 05_Classification, 06_WebGIS berada)
folder_analisis <- "C:/Users/nisri/OneDrive/Documents/Uni/Semester 5/Pemrograman Spasial/ETS/Folder/bantul-gis"

# Folder repositori GitHub di komputermu (tempat app.R berada)
folder_repo <- "C:/Users/nisri/OneDrive/Documents/Uni/Semester 5/Pemrograman Spasial/ETS/Folder/bantul-gis"
# -----------------------------------------------------------------------------

dir_deploy <- file.path(folder_repo, "data_deploy")
dir_output <- file.path(folder_repo, "output")
dir.create(dir_deploy, recursive = TRUE, showWarnings = FALSE)
dir.create(dir_output, recursive = TRUE, showWarnings = FALSE)

salin <- function(berkas, tujuan) {
  ada <- file.exists(berkas)
  if (any(!ada)) {
    warning("Tidak ditemukan:\n  ", paste(berkas[!ada], collapse = "\n  "), call. = FALSE)
  }
  ok <- file.copy(berkas[ada], tujuan, overwrite = TRUE)
  message(sprintf("[%s] %s", ifelse(ok, "OK", "GAGAL"), basename(berkas[ada])))
  invisible(ok)
}

# 1) Data untuk aplikasi -> data_deploy/
salin(file.path(folder_analisis, "04_Index",
                c("NDVI.tif", "NDBI.tif", "NDWI.tif", "NDCI.tif")), dir_deploy)
salin(file.path(folder_analisis, "05_Classification",
                "klasifikasi_tutupan_lahan_bantul.tif"), dir_deploy)
salin(file.path(folder_analisis, "06_WebGIS",
                c("hasil_analisis.gpkg", "hasil_analisis.rds")), dir_deploy)

# 2) Tabel CSV untuk laporan -> output/
salin(file.path(folder_analisis, "06_WebGIS",
                c("zonal_statistics_kecamatan.csv",
                  "statistik_kabupaten.csv",
                  "luas_tutupan_lahan_kecamatan.csv",
                  "threshold_klasifikasi.csv")), dir_output)

# 3) Pengecekan: 7 berkas utama harus lengkap agar aplikasi masuk mode deploy
wajib <- c("klasifikasi_tutupan_lahan_bantul.tif", "NDVI.tif", "NDBI.tif",
           "NDWI.tif", "NDCI.tif", "hasil_analisis.gpkg", "hasil_analisis.rds")
lengkap <- file.exists(file.path(dir_deploy, wajib))
names(lengkap) <- wajib
print(lengkap)

# 4) Ukuran berkas (GitHub menolak berkas di atas 100 MB)
info <- file.info(list.files(dir_deploy, full.names = TRUE))
ukuran <- data.frame(berkas = basename(rownames(info)),
                     MB = round(info$size / 1024^2, 2))
print(ukuran)
if (any(ukuran$MB > 100)) {
  warning("Ada berkas > 100 MB. GitHub akan menolaknya. Kompres atau perkecil dulu.",
          call. = FALSE)
}

if (all(lengkap)) {
  message("\nSemua berkas lengkap. Folder siap di-commit dan di-deploy.")
} else {
  message("\nMasih ada berkas yang belum lengkap. Cek pesan peringatan di atas.")
}
message("Catatan: tambahkan juga logo_its.png dan logo_geomatika.png ke data_deploy/ (opsional, untuk peta cetak).")
