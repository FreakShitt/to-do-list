
# 📱 Kalkulator To Do List

## 📌 Deskripsi Aplikasi

Aplikasi **Kalkulator To Do List** adalah aplikasi sederhana yang menggabungkan fitur kalkulator dan manajemen to-do list. Aplikasi ini dibangun menggunakan **Flutter (Frontend)** dan **Laravel (Backend API)**.

### ✨ Fitur Utama
- Halaman To Do List: Menambah, mengedit, dan menghapus tugas harian.

---

## 🧭 Halaman Aplikasi
1. **Halaman Utama** – Halaman To Do List CRUD daftar tugas.
---

## 🌐 API

- Dibangun dengan **Laravel 10+**
- Endpoints:
  - `GET /api/todos`
  - `POST /api/todos`
  - `PUT /api/todos/{id}`
  - `DELETE /api/todos/{id}`
  - dll.


---

## 🛠️ Software yang Digunakan

- Flutter 
- Laravel
- MySQL / XAMPP / Laragon
- Postman (untuk testing API)
- VS Code / Android Studio
- Git & GitHub

---

## ⚙️ Cara Instalasi

### Backend Laravel
1. Clone repository ini
2. Masuk ke folder backend Laravel
3. Jalankan perintah:
   ```bash
   composer install
   cp .env.example .env
   php artisan key:generate
   php artisan migrate
   php artisan serve
``

4. Sesuaikan koneksi database di `.env`

### Frontend Flutter

1. Masuk ke folder Flutter
2. Jalankan:

   ```bash
   flutter pub get
   flutter run
   ```
3. Pastikan API sudah jalan agar data bisa dimuat

---

## ▶️ Cara Menjalankan

1. Jalankan Laravel di `localhost:8000`
2. Jalankan Flutter emulator / device
3. Akses aplikasi seperti biasa
4. Data akan tersambung otomatis lewat API

---

## 📹 Demo

[**Klik di sini untuk melihat video demo**](https://link-ke-video-demo.com)


---

## 👤 Identitas Pembuat

* **Nama:** Satrio Parikesit
* **Kelas:** XI RPL 1
* **Sekolah:** SMKN 1 BANTUL


---

> Terima kasih sudah melihat proyek ini! Jika ada saran atau feedback, silakan kirim melalui GitHub Issue 🙌

```
