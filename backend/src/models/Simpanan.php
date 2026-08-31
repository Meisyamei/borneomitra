<?php
// src/models/Simpanan.php

require_once __DIR__ . '/../config/database.php';

class Simpanan {
    private $db;

    public function __construct() {
        global $pdo;
        $this->db = $pdo;
    }

    // ===== GET ALL =====
    public function getAll() {
        $stmt = $this->db->query("
            SELECT s.*, a.nama as nama_anggota
            FROM simpanan s
            JOIN anggota a ON s.anggota_id = a.id
            ORDER BY s.tanggal DESC
        ");
        return $stmt->fetchAll();
    }

    // ===== GET BY ID =====
    public function getById($id) {
        $stmt = $this->db->prepare("
            SELECT s.*, a.nama as nama_anggota
            FROM simpanan s
            JOIN anggota a ON s.anggota_id = a.id
            WHERE s.id = ?
        ");
        $stmt->execute([$id]);
        return $stmt->fetch();
    }

    // ===== GET BY ANGGOTA =====
    public function getByAnggota($anggotaId) {
        $stmt = $this->db->prepare("
            SELECT s.*, a.nama as nama_anggota
            FROM simpanan s
            JOIN anggota a ON s.anggota_id = a.id
            WHERE s.anggota_id = ?
            ORDER BY s.tanggal DESC
        ");
        $stmt->execute([$anggotaId]);
        return $stmt->fetchAll();
    }

    // ===== CREATE =====
    public function create($data) {
        $stmt = $this->db->prepare("
            INSERT INTO simpanan (anggota_id, jenis, tipe, nominal, tanggal, keterangan, created_at)
            VALUES (?, ?, ?, ?, ?, ?, NOW())
        ");
        $stmt->execute([
            $data['anggota_id'],
            $data['jenis'],
            $data['tipe'],
            $data['nominal'],
            $data['tanggal'],
            $data['keterangan'] ?? null,
        ]);
        return $this->db->lastInsertId();
    }

    // ===== GET TOTAL ANGGOTA =====
    public function getTotalByAnggota($anggotaId) {
        $stmt = $this->db->prepare("
            SELECT
                COALESCE(SUM(CASE WHEN tipe = 'masuk' THEN nominal ELSE 0 END), 0) as total_masuk,
                COALESCE(SUM(CASE WHEN tipe = 'keluar' THEN nominal ELSE 0 END), 0) as total_keluar
            FROM simpanan
            WHERE anggota_id = ?
        ");
        $stmt->execute([$anggotaId]);
        $result = $stmt->fetch();
        return $result['total_masuk'] - $result['total_keluar'];
    }

    // ===== GET TOTAL ALL =====
    public function getTotalAll() {
        $stmt = $this->db->query("
            SELECT
                COALESCE(SUM(CASE WHEN tipe = 'masuk' THEN nominal ELSE 0 END), 0) as total_masuk,
                COALESCE(SUM(CASE WHEN tipe = 'keluar' THEN nominal ELSE 0 END), 0) as total_keluar
            FROM simpanan
        ");
        $result = $stmt->fetch();
        return $result['total_masuk'] - $result['total_keluar'];
    }

    // ===== GET BY PERIODE =====
    public function getByPeriode($startDate, $endDate) {
        $stmt = $this->db->prepare("
            SELECT s.*, a.nama as nama_anggota
            FROM simpanan s
            JOIN anggota a ON s.anggota_id = a.id
            WHERE s.tanggal >= ? AND s.tanggal <= ?
            ORDER BY s.tanggal DESC
        ");
        $stmt->execute([$startDate, $endDate]);
        return $stmt->fetchAll();
    }
}
?>