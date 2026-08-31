cat > ~/koperasi/backend/src/models/Pinjaman.php << 'EOF'
<?php
// src/models/Pinjaman.php

require_once __DIR__ . '/../config/database.php';

class Pinjaman {
    private $db;

    public function __construct() {
        global $pdo;
        $this->db = $pdo;
    }

    // ===== GET ALL =====
    public function getAll() {
        $stmt = $this->db->query("
            SELECT p.*, a.nama as nama_anggota, a.nik
            FROM pinjaman p
            JOIN anggota a ON p.anggota_id = a.id
            ORDER BY p.tanggal_pinjam DESC
        ");
        return $stmt->fetchAll();
    }

    // ===== GET BY ID =====
    public function getById($id) {
        $stmt = $this->db->prepare("
            SELECT p.*, a.nama as nama_anggota, a.nik
            FROM pinjaman p
            JOIN anggota a ON p.anggota_id = a.id
            WHERE p.id = ?
        ");
        $stmt->execute([$id]);
        return $stmt->fetch();
    }

    // ===== GET BY ANGGOTA =====
    public function getByAnggota($anggotaId) {
        $stmt = $this->db->prepare("
            SELECT p.*, a.nama as nama_anggota, a.nik
            FROM pinjaman p
            JOIN anggota a ON p.anggota_id = a.id
            WHERE p.anggota_id = ?
            ORDER BY p.tanggal_pinjam DESC
        ");
        $stmt->execute([$anggotaId]);
        return $stmt->fetchAll();
    }

    // ===== GET BY STATUS =====
    public function getByStatus($status) {
        $stmt = $this->db->prepare("
            SELECT p.*, a.nama as nama_anggota, a.nik
            FROM pinjaman p
            JOIN anggota a ON p.anggota_id = a.id
            WHERE p.status = ?
            ORDER BY p.tanggal_pinjam DESC
        ");
        $stmt->execute([$status]);
        return $stmt->fetchAll();
    }

    // ===== CREATE =====
    public function create($data) {
        $this->db->beginTransaction();

        try {
            // Insert pinjaman
            $stmt = $this->db->prepare("
                INSERT INTO pinjaman (anggota_id, jumlah, bunga, tenor, tanggal_pinjam, status,
                                      denda_keterlambatan, sisa_pinjaman, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, 'aktif', ?, ?, NOW(), NOW())
            ");
            $stmt->execute([
                $data['anggota_id'],
                $data['jumlah'],
                $data['bunga'] ?? 12,
                $data['tenor'],
                $data['tanggal_pinjam'],
                $data['denda_keterlambatan'] ?? 50000,
                $data['jumlah'],
            ]);

            $pinjamanId = $this->db->lastInsertId();

            // Generate angsuran
            $angsuranPerBulan = $this->hitungAngsuran($data['jumlah'], $data['bunga'] ?? 12, $data['tenor']);
            for ($i = 1; $i <= $data['tenor']; $i++) {
                $jatuhTempo = date('Y-m-d', strtotime($data['tanggal_pinjam'] . " +$i months"));
                $stmtAngsuran = $this->db->prepare("
                    INSERT INTO angsuran (pinjaman_id, angsuran_ke, nominal, tanggal_jatuh_tempo, status)
                    VALUES (?, ?, ?, ?, 'belum_bayar')
                ");
                $stmtAngsuran->execute([$pinjamanId, $i, $angsuranPerBulan, $jatuhTempo]);
            }

            // Update total pinjaman anggota
            require_once __DIR__ . '/Anggota.php';
            $anggota = new Anggota();
            $anggota->updateTotalPinjaman($data['anggota_id'], $data['jumlah']);

            $this->db->commit();
            return $pinjamanId;
        } catch (Exception $e) {
            $this->db->rollBack();
            throw $e;
        }
    }

    // ===== UPDATE =====
    public function update($id, $data) {
        $fields = [];
        $params = [];

        $allowedFields = ['jumlah', 'bunga', 'tenor', 'status', 'denda_keterlambatan', 'sisa_pinjaman'];
        foreach ($allowedFields as $field) {
            if (array_key_exists($field, $data)) {
                $fields[] = "$field = ?";
                $params[] = $data[$field];
            }
        }

        if (empty($fields)) return false;

        $params[] = $id;
        $sql = "UPDATE pinjaman SET " . implode(', ', $fields) . ", updated_at = NOW() WHERE id = ?";
        $stmt = $this->db->prepare($sql);
        return $stmt->execute($params);
    }

    // ===== UPDATE STATUS =====
    public function updateStatus($id, $status) {
        $stmt = $this->db->prepare("UPDATE pinjaman SET status = ?, updated_at = NOW() WHERE id = ?");
        return $stmt->execute([$status, $id]);
    }

    // ===== UPDATE SISA =====
    public function updateSisa($id, $sisa) {
        $stmt = $this->db->prepare("UPDATE pinjaman SET sisa_pinjaman = ?, updated_at = NOW() WHERE id = ?");
        return $stmt->execute([$sisa, $id]);
    }

    // ===== HITUNG ANGSURAN =====
    public function hitungAngsuran($jumlah, $bunga, $tenor) {
        $totalBunga = $jumlah * ($bunga / 100);
        $totalHarusBayar = $jumlah + $totalBunga;
        return $totalHarusBayar / $tenor;
    }

    // ===== DELETE =====
    public function delete($id) {
        $stmt = $this->db->prepare("DELETE FROM pinjaman WHERE id = ?");
        return $stmt->execute([$id]);
    }
}
?>
EOF