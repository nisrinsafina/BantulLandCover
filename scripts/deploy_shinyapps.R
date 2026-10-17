# DEPLOY KE SHINYAPPS.IO

# Langkah:
#   1. Sign Up di https://www.shinyapps.io
#   2. Buka Account > Tokens > Show, lalu salin name, token, dan secret
#   3. Isi tiga nilai di bawah ini (cukup dijalankan SEKALI)
#   4. Ubah folder_repo ke lokasi repositori di komputermu
#   5. Jalankan seluruh script ini


# Setelah akun terdaftar, kosongkan kembali nilai-nilai di bawah sebelum git commit.
# =============================================================================

# --- ISI BAGIAN INI ----------------------------------------------------------
akun   <- ""   # name   (username shinyapps.io)
token  <- ""   # token
secret <- ""   # secret

folder_repo <- "C:/Users/NAMAKAMU/Documents/bantul-gis"
nama_app    <- "bantul-landcover"

# Link akhir: https://<akun>.shinyapps.io/<nama_app>/
# -----------------------------------------------------------------------------

if (!requireNamespace("rsconnect", quietly = TRUE)) install.packages("rsconnect")

# 1) Hubungkan akun (dilewati kalau kolom di atas masih kosong)
if (nzchar(akun) && nzchar(token) && nzchar(secret)) {
  rsconnect::setAccountInfo(name = akun, token = token, secret = secret)
} else {
  message("Kolom akun/token/secret kosong. Dianggap akun sudah terhubung sebelumnya.")
}

# 2) Cek kelengkapan berkas sebelum upload
setwd(folder_repo)
wajib <- c("app.R", "dependencies.R",
           file.path("data_deploy", c("klasifikasi_tutupan_lahan_bantul.tif",
                                      "NDVI.tif", "NDBI.tif", "NDWI.tif", "NDCI.tif",
                                      "hasil_analisis.gpkg", "hasil_analisis.rds")))
hilang <- wajib[!file.exists(wajib)]
if (length(hilang) > 0) {
  stop("Berkas berikut belum ada:\n  ", paste(hilang, collapse = "\n  "), call. = FALSE)
}

# 3) Upload (hanya berkas yang dibutuhkan aplikasi; folder lain tidak ikut)
rsconnect::deployApp(
  appDir   = ".",
  appFiles = c("app.R", "dependencies.R", "data_deploy"),
  appName  = nama_app,
  forceUpdate = TRUE
)

# Jika ada error di server, lihat lognya dengan:
# rsconnect::showLogs(appName = nama_app)
