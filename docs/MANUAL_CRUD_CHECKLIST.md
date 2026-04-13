# Manual CRUD Checklist

Gunakan checklist ini saat smoke test Flutter terhadap backend Laravel. Semua data acuan ada di [DUMMY_DATA_SCENARIOS.md](/C:/laragon/www/flutter_ujikom/docs/DUMMY_DATA_SCENARIOS.md).

## Persiapan

- [ ] Backend Laravel `Ujikom` berjalan dan endpoint `/api` bisa diakses.
- [ ] Frontend Flutter `flutter_ujikom` berjalan dan bisa login ke API.
- [ ] `php artisan storage:link` sudah siap.
- [ ] Database sudah diseed.
- [ ] Akun admin `admin@nokomi.test / password` bisa login.
- [ ] Akun uploader `asep@nokomi.test / password` bisa login.
- [ ] File uji upload tersedia: `mobile-cover.png`, `mobile-cover-revised.png`, `page-1.png`, `page-2.png`, `page-10.png`, `invalid-file.txt`.

## Admin - Genre

- [ ] Buka menu `Kelola Genre`.
- [ ] Tambah genre `Regression Genre Mobile`.
- [ ] Genre baru langsung muncul di list Flutter.
- [ ] Edit genre menjadi `Regression Genre Mobile Updated`.
- [ ] Nama genre berubah tanpa data lama tertinggal.
- [ ] Coba submit nama kosong dan tampil error validasi Laravel.
- [ ] Coba submit nama duplikat dan tampil error validasi Laravel.
- [ ] Biarkan genre ini tetap ada sampai pengujian work selesai.

## Uploader - Work

- [ ] Buka menu `Kelola Karya`.
- [ ] Tambah work baru `Mobile CRUD Comic`.
- [ ] Pilih type `comic`.
- [ ] Pilih genre `Action`, `Fantasy`, dan `Regression Genre Mobile Updated`.
- [ ] Upload cover `mobile-cover.png`.
- [ ] Work baru muncul di list uploader dengan status `draft`.
- [ ] Edit work menjadi `Mobile CRUD Comic Revised`.
- [ ] Ganti deskripsi dan genre menjadi `Action` dan `Thriller`.
- [ ] Ganti cover menjadi `mobile-cover-revised.png`.
- [ ] Data hasil edit tampil benar di list.
- [ ] Coba create atau update tanpa genre dan tampil error.
- [ ] Coba upload `invalid-file.txt` sebagai cover dan tampil error.
- [ ] Submit work ke admin.
- [ ] Status work berubah menjadi `pending`.

## Uploader - Chapter

- [ ] Buka menu `Kelola Chapter` untuk work `Mobile CRUD Comic Revised`.
- [ ] Tambah chapter nomor `91` dengan judul `Kickoff Mobile Chapter`.
- [ ] Chapter baru muncul di list.
- [ ] Edit chapter menjadi nomor `92` dengan judul `Kickoff Mobile Chapter Updated`.
- [ ] Isi text content hasil update tersimpan.
- [ ] Coba create chapter duplikat pada nomor yang sama dan tampil error.
- [ ] Coba create atau update dengan nomor `0` dan tampil error.

## Uploader - Chapter Image

- [ ] Buka menu `Kelola Gambar Chapter` untuk chapter `Kickoff Mobile Chapter Updated`.
- [ ] Upload minimal 2 file image: `page-1.png` dan `page-2.png`.
- [ ] Semua gambar tampil di list dengan urutan page number yang benar.
- [ ] Edit salah satu gambar dan ubah `page_number` menjadi `10`.
- [ ] Ganti file image itu menjadi `page-10.png`.
- [ ] Page number baru tersimpan.
- [ ] Preview atau URL image berubah setelah replace file.
- [ ] Coba upload tanpa file dan tampil error.
- [ ] Coba upload `invalid-file.txt` dan tampil error.
- [ ] Coba update image dengan `page_number = 0` dan tampil error.
- [ ] Hapus gambar dengan page number `10`.
- [ ] Gambar hilang dari list.

## Admin - Moderasi

- [ ] Login sebagai admin.
- [ ] Buka `Approval Karya`.
- [ ] Work `Mobile CRUD Comic Revised` muncul pada daftar approval.
- [ ] Approve work.
- [ ] Status work di portal admin berubah menjadi `approved`.
- [ ] Login kembali sebagai uploader dan pastikan status juga `approved`.
- [ ] Jika menguji reject, submit ulang work lalu reject dari admin.
- [ ] Pastikan status work uploader kembali menjadi `draft`.
- [ ] Hapus work dari panel admin.
- [ ] Work hilang dari panel admin.

## Cleanup

- [ ] Login kembali sebagai admin.
- [ ] Hapus genre `Regression Genre Mobile Updated`.
- [ ] Genre hilang dari list admin.

## Konsistensi Akhir

- [ ] Work yang dihapus tidak muncul lagi di portal uploader.
- [ ] Chapter terkait tidak muncul lagi.
- [ ] Image terkait tidak muncul lagi.
- [ ] Tidak ada crash UI setelah urutan create, update, delete, dan submit.
- [ ] `flutter analyze` lulus.
- [ ] `php artisan test` lulus.
- [ ] `flutter test` lulus.
