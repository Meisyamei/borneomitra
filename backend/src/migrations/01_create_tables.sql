-- src/migrations/01_create_tables.sql

CREATE DATABASE IF NOT EXISTS koperasi;
USE koperasi;

-- ========================================
-- 1. TABEL ADMIN
-- ========================================
CREATE TABLE IF NOT EXISTS admin (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nama_lengkap VARCHAR(100),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Default admin (password: admin123)
INSERT INTO admin (username, password_hash, nama_lengkap)
VALUES ('admin', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Administrator');

-- ========================================
-- 2. TABEL ANGGOTA
-- ========================================
CREATE TABLE IF NOT EXISTS anggota (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nik VARCHAR(20) UNIQUE NOT NULL,
    nama VARCHAR(100) NOT NULL,
    alamat TEXT,
    no_hp VARCHAR(15),
    total_simpanan DECIMAL(15,2) DEFAULT 0,
    total_pinjaman DECIMAL(15,2) DEFAULT 0,
    tanggal_daftar DATE,
    status ENUM('aktif', 'nonaktif') DEFAULT 'aktif',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_nik (nik),
    INDEX idx_nama (nama)
);

-- ========================================
-- 3. TABEL SIMPANAN
-- ========================================
CREATE TABLE IF NOT EXISTS simpanan (
    id INT AUTO_INCREMENT PRIMARY KEY,
    anggota_id INT NOT NULL,
    jenis ENUM('wajib', 'sukarela', 'pokok') NOT NULL,
    tipe ENUM('masuk', 'keluar') DEFAULT 'masuk',
    nominal DECIMAL(15,2) NOT NULL,
    tanggal DATE NOT NULL,
    keterangan TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (anggota_id) REFERENCES anggota(id) ON DELETE CASCADE,
    INDEX idx_anggota (anggota_id),
    INDEX idx_tanggal (tanggal)
);

-- ========================================
-- 4. TABEL PINJAMAN
-- ========================================
CREATE TABLE IF NOT EXISTS pinjaman (
    id INT AUTO_INCREMENT PRIMARY KEY,
    anggota_id INT NOT NULL,
    jumlah DECIMAL(15,2) NOT NULL,
    bunga DECIMAL(5,2) DEFAULT 12,
    tenor INT NOT NULL,
    tanggal_pinjam DATE NOT NULL,
    status ENUM('aktif', 'lunas', 'menunggak') DEFAULT 'aktif',
    denda_keterlambatan DECIMAL(15,2) DEFAULT 50000,
    sisa_pinjaman DECIMAL(15,2) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (anggota_id) REFERENCES anggota(id) ON DELETE CASCADE,
    INDEX idx_anggota (anggota_id),
    INDEX idx_status (status)
);

-- ========================================
-- 5. TABEL ANGSURAN
-- ========================================
CREATE TABLE IF NOT EXISTS angsuran (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pinjaman_id INT NOT NULL,
    angsuran_ke INT NOT NULL,
    nominal DECIMAL(15,2) NOT NULL,
    denda DECIMAL(15,2) DEFAULT 0,
    tanggal_jatuh_tempo DATE NOT NULL,
    tanggal_bayar DATE NULL,
    status ENUM('belum_bayar', 'lunas') DEFAULT 'belum_bayar',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (pinjaman_id) REFERENCES pinjaman(id) ON DELETE CASCADE,
    INDEX idx_pinjaman (pinjaman_id),
    INDEX idx_status (status),
    INDEX idx_jatuh_tempo (tanggal_jatuh_tempo)
);

-- ========================================
-- 6. TABEL ARISAN
-- ========================================
CREATE TABLE IF NOT EXISTS arisan (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nama VARCHAR(100) NOT NULL,
    iuran DECIMAL(15,2) NOT NULL,
    biaya_admin DECIMAL(15,2) DEFAULT 0,
    total_bulan INT DEFAULT 0,
    bulan_berjalan INT DEFAULT 1,
    tanggal_mulai DATE NOT NULL,
    tanggal_selesai DATE,
    status ENUM('aktif', 'selesai') DEFAULT 'aktif',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ========================================
-- 7. TABEL PESERTA ARISAN
-- ========================================
CREATE TABLE IF NOT EXISTS peserta_arisan (
    id INT AUTO_INCREMENT PRIMARY KEY,
    arisan_id INT NOT NULL,
    anggota_id INT NOT NULL,
    nomor_urut INT NOT NULL,
    status ENUM('aktif', 'sudah_menang') DEFAULT 'aktif',
    tanggal_menang DATE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (arisan_id) REFERENCES arisan(id) ON DELETE CASCADE,
    FOREIGN KEY (anggota_id) REFERENCES anggota(id) ON DELETE CASCADE,
    INDEX idx_arisan (arisan_id),
    INDEX idx_anggota (anggota_id)
);

-- ========================================
-- 8. TABEL PEMBAYARAN ARISAN
-- ========================================
CREATE TABLE IF NOT EXISTS pembayaran_arisan (
    id INT AUTO_INCREMENT PRIMARY KEY,
    peserta_id INT NOT NULL,
    periode_ke INT NOT NULL,
    nominal DECIMAL(15,2) NOT NULL,
    tanggal_bayar DATE NOT NULL,
    status ENUM('belum_bayar', 'lunas') DEFAULT 'belum_bayar',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (peserta_id) REFERENCES peserta_arisan(id) ON DELETE CASCADE,
    INDEX idx_peserta (peserta_id)
);

-- ========================================
-- 9. TABEL NOTIFIKASI
-- ========================================
CREATE TABLE IF NOT EXISTS notifikasi (
    id INT AUTO_INCREMENT PRIMARY KEY,
    judul VARCHAR(255) NOT NULL,
    pesan TEXT NOT NULL,
    jenis ENUM('info', 'warning', 'danger', 'success') DEFAULT 'info',
    tanggal DATETIME NOT NULL,
    dibaca TINYINT DEFAULT 0,
    dihapus TINYINT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ========================================
-- 10. TABEL SYNC PENDING
-- ========================================
CREATE TABLE IF NOT EXISTS sync_pending (
    id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    data TEXT NOT NULL,
    status ENUM('pending', 'synced') DEFAULT 'pending',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ========================================
-- 11. TABEL PROFILE
-- ========================================
CREATE TABLE IF NOT EXISTS profile (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nama VARCHAR(100) DEFAULT 'Administrator',
    email VARCHAR(100) DEFAULT 'admin@bms.com',
    foto_path VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insert default profile
INSERT INTO profile (nama, email) VALUES ('Administrator', 'admin@bms.com');

-- ========================================
-- SHOW TABLES
-- ========================================
SHOW TABLES;