# Dummy Data Scenarios

Dokumen ini dipakai untuk menjalankan uji CRUD end-to-end antara backend Laravel `Ujikom` dan frontend Flutter `flutter_ujikom`.

## Akun Seed

Semua akun seed default memakai password `password`.

| Role | Email | Dipakai untuk |
| --- | --- | --- |
| Admin | `admin@nokomi.test` | CRUD admin, approval, moderasi |
| Uploader | `asep@nokomi.test` | CRUD work, chapter, chapter image |
| Uploader | `nayla@nokomi.test` | Cross-check isolation data uploader lain |
| User | `rani@nokomi.test` | Validasi role non-admin/non-uploader |

## File Uji Upload

Siapkan file kecil berikut di mesin pengujian:

| Kebutuhan | Nama file contoh | Catatan |
| --- | --- | --- |
| Cover valid | `mobile-cover.png` | PNG/JPG/WEBP, ukuran kecil |
| Cover update valid | `mobile-cover-revised.png` | Dipakai saat update work |
| Gambar chapter 1 | `page-1.png` | Image valid |
| Gambar chapter 2 | `page-2.png` | Image valid |
| Gambar chapter update | `page-10.png` | Dipakai replace image |
| File invalid | `invalid-file.txt` | Untuk uji validasi non-image |

## Data Dummy Utama

### Genre Admin

| Langkah | Nilai |
| --- | --- |
| Create | `Regression Genre Mobile` |
| Update | `Regression Genre Mobile Updated` |
| Delete | `Regression Genre Mobile Updated` |

### Work Uploader

| Field | Create | Update |
| --- | --- | --- |
| Title | `Mobile CRUD Comic` | `Mobile CRUD Comic Revised` |
| Original author | `QA Automation Team` | `QA Automation Team` |
| Type | `comic` | `comic` |
| Genre | `Action`, `Fantasy`, `Regression Genre Mobile Updated` | `Action`, `Thriller` |
| Description | `Work comic untuk validasi CRUD uploader dari Flutter.` | `Versi revisi work comic untuk validasi update.` |
| Cover | `mobile-cover.png` | `mobile-cover-revised.png` |
| Target status submit | `pending` | `pending` |

### Chapter Uploader

| Field | Create | Update |
| --- | --- | --- |
| Work target | `Mobile CRUD Comic Revised` | `Mobile CRUD Comic Revised` |
| Chapter number | `91` | `92` |
| Title | `Kickoff Mobile Chapter` | `Kickoff Mobile Chapter Updated` |
| Text content | `Chapter ini dipakai untuk validasi create chapter via Flutter.` | `Chapter ini sudah diperbarui untuk validasi update.` |

### Chapter Image Uploader

| Langkah | Nilai |
| --- | --- |
| Upload awal | `page-1.png`, `page-2.png` |
| Update page number | `10` |
| Replace file | `page-10.png` |
| Delete target | image dengan `page_number = 10` |

## Alur Skenario Positif

### 1. Genre Admin

- Login admin dengan `admin@nokomi.test`.
- Create genre `Regression Genre Mobile`.
- Update menjadi `Regression Genre Mobile Updated`.
- Simpan untuk dipakai saat create work uploader.
- Delete dilakukan paling akhir setelah flow uploader selesai.

### 2. Work Uploader

- Login uploader dengan `asep@nokomi.test`.
- Create work `Mobile CRUD Comic`.
- Update menjadi `Mobile CRUD Comic Revised`.
- Submit work dan pastikan status berubah dari `draft` ke `pending`.

### 3. Chapter Uploader

- Pada work `Mobile CRUD Comic Revised`, create chapter nomor `91`.
- Update chapter menjadi nomor `92`.
- Gunakan chapter ini untuk flow upload image.

### 4. Chapter Image Uploader

- Upload `page-1.png` dan `page-2.png`.
- Edit salah satu image menjadi `page_number = 10`.
- Replace file dengan `page-10.png`.
- Hapus image `page_number = 10`.

### 5. Moderasi Admin

- Login admin.
- Cari work `Mobile CRUD Comic Revised`.
- Approve work dari status `pending` menjadi `approved`.
- Jika perlu uji reject, submit ulang dari uploader lalu reject hingga kembali `draft`.
- Hapus work dari panel admin.

### 6. Cleanup

- Hapus sisa chapter jika work belum dihapus.
- Hapus genre `Regression Genre Mobile Updated`.
- Pastikan file upload yang terkait work test tidak lagi muncul di portal.

## Skenario Negatif

### Genre

- Nama kosong.
- Nama duplikat dengan genre yang sudah ada.

### Work

- `genre_ids` kosong.
- `type` selain `comic` atau `novel`.
- Upload `invalid-file.txt` sebagai cover.

### Chapter

- `chapter_number` duplikat pada work yang sama.
- `chapter_number = 0`.

### Chapter Image

- Submit tanpa file image.
- Upload `invalid-file.txt`.
- Update `page_number = 0`.

## Ekspektasi Hasil

- Semua aksi sukses menampilkan data baru di list Flutter tanpa refresh manual yang membingungkan.
- Semua validasi gagal menampilkan pesan dari Laravel, bukan error generik.
- Setelah delete, data hilang dari list dan tidak muncul lagi setelah reload halaman.
- Status work konsisten antara panel uploader dan panel admin.
