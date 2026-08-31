<?php
// src/models/Angsuran.php

require_once __DIR__ . '/../config/database.php';

class Angsuran {
    private $db;

    public function __construct() {
        global $pdo;
        $this->db = $pdo;
    }

    // ===== GET ALL =====
    public function getAll($pinjamanId = null) {
        $sql = "
            SELECT a.*, p.anggota_id, ag.nama as nama_anggota, p.jumlah as jumlah_pinjaman
            FROM angsuran a
            JOIN pinjaman p ON a.pinjaman_id = p.id
            JOIN anggota ag ON p.anggota_id = ag.id
        ";
        if ($pinjamanId) {
            $sql .= " WHERE a.pinjaman_id = " . intval($pinjamanId);
        }
        $sql .= " ORDER BY a.tanggal_jatuh_tempo ASC";

        $stmt = $this->db->query($sql);
        return $stmt->fetchAll();
    }

    // ===== GET BY ID =====
    public function getById($id) {
        $stmt = $this->db->prepare("
            SELECT a.*, p.anggota_id, ag.nama as nama_anggota, p.jumlah as jumlah_pinjaman
            FROM angsuran a
            JOIN pinjaman p ON a.pinjaman_id = p.id
            JOIN anggota ag ON p.anggota_id = ag.id
            WHERE a.id = ?
        ");
        $stmt->execute([$id]);
        return $stmt->fetch();
    }

    // ===== GET BY PINJAMAN =====
    public function getByPinjaman($pinjamanId) {
        $stmt = $this->db->prepare("
            SELECT a.*, p.anggota_id, ag.nama as nama_anggota, p.jumlah as jumlah_pinjaman
            FROM angsuran a
            JOIN pinjaman p ON a.pinjaman_id = p.id
            JOIN anggota ag ON p.anggota_id = ag.id
            WHERE a.pinjaman_id = ?
            ORDER BY a.angsuran_ke ASC
        ");
        $stmt->execute([$pinjamanId]);
        return $stmt->fetchAll();
    }

    // ===== CREATE =====
    public function create($data) {
        $stmt = $this->db->prepare("
            INSERT INTO angsuran (pinjaman_id, angsuran_ke, nominal, denda,
                                  tanggal_jatuh_tempo, status, created_at)
            VALUES (?, ?, ?, ?, ?, ?, NOW())
        ");
        $stmt->execute([
            $data['pinjaman_id'],
            $data['angsuran_ke'],
            $data['nominal'],
            $data['denda'] ?? 0,
            $data['tanggal_jatuh_tempo'],
            $data['status'] ?? 'belum_bayar',
        ]);
        return $this->db->lastInsertId();
    }

    // ===== BAYAR =====
    public function bayar($angsuranId, $tanggalBayar, $denda = 0) {
        $this->db->beginTransaction();

        try {
            // Update angsuran
            $stmt = $this->db->prepare("
                UPDATE angsuran
                SET tanggal_bayar = ?, status = 'lunas', denda = ?, updated_at = NOW()
                WHERE id = ?
            ");
            $stmt->execute([$tanggalBayar, $denda, $angsuranId]);

            // Ambil angsuran untuk dapat pinjaman_id dan nominal
            $angsuran = $this->getById($angsuranId);
            if (!$angsuran) {
                throw new Exception('Angsuran tidak ditemukan');
            }

            $pinjamanId = $angsuran['pinjaman_id'];
            $nominal = $angsuran['nominal'];

            // Update sisa pinjaman
            require_once __DIR__ . '/Pinjaman.php';
            $pinjaman = new Pinjaman();
            $pinjamanData = $pinjaman->getById($pinjamanId);

            if ($pinjamanData) {
                $sisaBaru = $pinjamanData['sisa_pinjaman'] - $nominal;
                if ($sisaBaru < 0) $sisaBaru = 0;

                $pinjaman->updateSisa($pinjamanId, $sisaBaru);

                // Jika sisa = 0, update status pinjaman menjadi lunas
                if ($sisaBaru <= 0) {
                    $pinjaman->updateStatus($pinjamanId, 'lunas');

                    // Update total pinjaman anggota (kurangi)
                    require_once __DIR__ . '/Anggota.php';
                    $anggota = new Anggota();
                    $anggota->updateTotalPinjaman($pinjamanData['anggota_id'], -$pinjamanData['jumlah']);
                }
            }

            $this->db->commit();
            return true;
        } catch (Exception $e) {
            $this->db->rollBack();
            throw $e;
        }
    }

    // ===== GET TUNGGAKAN =====
    public function getTunggakan() {
        $stmt = $this->db->query("
            SELECT a.*, p.anggota_id, ag.nama as nama_anggota, p.jumlah as jumlah_pinjaman
            FROM angsuran a
            JOIN pinjaman p ON a.pinjaman_id = p.id
            JOIN anggota ag ON p.anggota_id = ag.id
            WHERE a.status = 'belum_bayar'
              AND a.tanggal_jatuh_tempo < CURDATE()
            ORDER BY a.tanggal_jatuh_tempo ASC
        ");
        return $stmt->fetchAll();
    }

    // ===== GET JATUH TEMPO HARI INI =====
    public function getJatuhTempoHariIni() {
        $stmt = $this->db->query("
            SELECT a.*, p.anggota_id, ag.nama as nama_anggota, p.jumlah as jumlah_pinjaman
            FROM angsuran a
            JOIN pinjaman p ON a.pinjaman_id = p.id
            JOIN anggota ag ON p.anggota_id = ag.id
            WHERE a.status = 'belum_bayar'
              AND DATE(a.tanggal_jatuh_tempo) = CURDATE()
            ORDER BY a.angsuran_ke ASC
        ");
        return $stmt->fetchAll();
    }

    // ===== GET HAMPIR JATUH TEMPO =====
    public function getHampirJatuhTempo() {
        $stmt = $this->db->query("
            SELECT a.*, p.anggota_id, ag.nama as nama_anggota, p.jumlah as jumlah_pinjaman
            FROM angsuran a
            JOIN pinjaman p ON a.pinjaman_id = p.id
            JOIN anggota ag ON p.anggota_id = ag.id
            WHERE a.status = 'belum_bayar'
              AND a.tanggal_jatuh_tempo > CURDATE()
              AND a.tanggal_jatuh_tempo <= DATE_ADD(CURDATE(), INTERVAL 3 DAY)
            ORDER BY a.tanggal_jatuh_tempo ASC
        ");
        return $stmt->fetchAll();
    }

    // ===== HITUNG DENDA =====
    public function hitungDenda($tanggalJatuhTempo, $tanggalBayar) {
        if ($tanggalBayar <= $tanggalJatuhTempo) {
            return 0;
        }

        $diff = date_diff(date_create($tanggalJatuhTempo), date_create($tanggalBayar));
        $hariTerlambat = $diff->days;
        $bulanTerlambat = ceil($hariTerlambat / 30);

        return $bulanTerlambat * 50000;
    }
}
?>