-- db/conf.d/init.sql

CREATE DATABASE IF NOT EXISTS koperasi;
USE koperasi;

-- ===== TABEL ANGGOTA =====
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

-- ===== TABEL SIMPANAN =====
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

-- ===== TABEL PINJAMAN =====
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

-- ===== TABEL ANGSURAN =====
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

-- ===== TABEL ADMIN =====
CREATE TABLE IF NOT EXISTS admin (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nama_lengkap VARCHAR(100),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Insert default admin
INSERT INTO admin (username, password_hash, nama_lengkap) 
VALUES ('admin', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Administrator');
-- password: admin123