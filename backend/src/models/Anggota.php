<?php
// src/models/Anggota.php
// Model untuk tabel anggota

require_once __DIR__ . '/../config/database.php';

class Anggota {
    private $db;

    public function __construct() {
        global $pdo;
        $this->db = $pdo;
    }

    // ===== GET ALL =====
    public function getAll($limit = null) {
        $sql = "SELECT id, nik, nama, alamat, no_hp, total_simpanan, total_pinjaman,
                       tanggal_daftar, status, created_at, updated_at
                FROM anggota ORDER BY id DESC";
        if ($limit) {
            $sql .= " LIMIT " . intval($limit);
        }
        $stmt = $this->db->query($sql);
        return $stmt->fetchAll();
    }

    // ===== GET BY ID =====
    public function getById($id) {
        $stmt = $this->db->prepare("SELECT * FROM anggota WHERE id = ?");
        $stmt->execute([$id]);
        return $stmt->fetch();
    }

    // ===== GET BY NIK =====
    public function getByNik($nik) {
        $stmt = $this->db->prepare("SELECT * FROM anggota WHERE nik = ?");
        $stmt->execute([$nik]);
        return $stmt->fetch();
    }

    // ===== SEARCH =====
    public function search($keyword) {
        $keyword = "%$keyword%";
        $stmt = $this->db->prepare("
            SELECT id, nik, nama, alamat, no_hp, total_simpanan, total_pinjaman,
                   tanggal_daftar, status
            FROM anggota
            WHERE nama LIKE ? OR nik LIKE ? OR alamat LIKE ?
            ORDER BY nama ASC
        ");
        $stmt->execute([$keyword, $keyword, $keyword]);
        return $stmt->fetchAll();
    }

    // ===== CREATE =====
    public function create($data) {
        $stmt = $this->db->prepare("
            INSERT INTO anggota (nik, nama, alamat, no_hp, total_simpanan, total_pinjaman,
                                 tanggal_daftar, status, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
        ");
        $stmt->execute([
            $data['nik'],
            $data['nama'],
            $data['alamat'] ?? '',
            $data['no_hp'] ?? '',
            $data['total_simpanan'] ?? 0,
            $data['total_pinjaman'] ?? 0,
            $data['tanggal_daftar'] ?? date('Y-m-d'),
            $data['status'] ?? 'aktif',
        ]);
        return $this->db->lastInsertId();
    }

    // ===== UPDATE =====
    public function update($id, $data) {
        $fields = [];
        $params = [];

        $allowedFields = ['nik', 'nama', 'alamat', 'no_hp', 'total_simpanan', 'total_pinjaman', 'status'];
        foreach ($allowedFields as $field) {
            if (array_key_exists($field, $data)) {
                $fields[] = "$field = ?";
                $params[] = $data[$field];
            }
        }

        if (empty($fields)) return false;

        $params[] = $id;
        $sql = "UPDATE anggota SET " . implode(', ', $fields) . ", updated_at = NOW() WHERE id = ?";
        $stmt = $this->db->prepare($sql);
        return $stmt->execute($params);
    }

    // ===== DELETE =====
    public function delete($id) {
        $stmt = $this->db->prepare("DELETE FROM anggota WHERE id = ?");
        return $stmt->execute([$id]);
    }

    // ===== GET TOTAL =====
    public function getTotal() {
        $stmt = $this->db->query("SELECT COUNT(*) as total FROM anggota");
        return $stmt->fetch()['total'];
    }

    // ===== UPDATE TOTAL SIMPANAN =====
    public function updateTotalSimpanan($id, $nominal) {
        $stmt = $this->db->prepare("
            UPDATE anggota SET total_simpanan = total_simpanan + ?, updated_at = NOW()
            WHERE id = ?
        ");
        return $stmt->execute([$nominal, $id]);
    }

    // ===== UPDATE TOTAL PINJAMAN =====
    public function updateTotalPinjaman($id, $nominal) {
        $stmt = $this->db->prepare("
            UPDATE anggota SET total_pinjaman = total_pinjaman + ?, updated_at = NOW()
            WHERE id = ?
        ");
        return $stmt->execute([$nominal, $id]);
    }
}
?>