cat > ~/koperasi/backend/src/controllers/PinjamanController.php << 'EOF'
<?php
// src/controllers/PinjamanController.php

require_once __DIR__ . '/../models/Pinjaman.php';

class PinjamanController {
    private $model;

    public function __construct() {
        $this->model = new Pinjaman();
    }

    // ===== GET ALL =====
    public function index() {
        $data = $this->model->getAll();
        successResponse($data);
    }

    // ===== GET BY ID =====
    public function show($id) {
        $data = $this->model->getById($id);
        if ($data) {
            successResponse($data);
        } else {
            errorResponse('Pinjaman tidak ditemukan', 404);
        }
    }

    // ===== GET BY ANGGOTA =====
    public function byAnggota($anggotaId) {
        $data = $this->model->getByAnggota($anggotaId);
        successResponse($data);
    }

    // ===== GET BY STATUS =====
    public function byStatus($status) {
        $data = $this->model->getByStatus($status);
        successResponse($data);
    }

    // ===== CREATE =====
    public function store() {
        $input = json_decode(file_get_contents('php://input'), true);

        if (!isset($input['anggota_id']) || !isset($input['jumlah']) || !isset($input['tenor'])) {
            errorResponse('Field wajib: anggota_id, jumlah, tenor');
            return;
        }

        try {
            $id = $this->model->create($input);
            successResponse(['id' => $id], 'Pinjaman berhasil ditambahkan');
        } catch (Exception $e) {
            errorResponse('Gagal menambahkan pinjaman: ' . $e->getMessage(), 500);
        }
    }

    // ===== UPDATE =====
    public function update($id) {
        $input = json_decode(file_get_contents('php://input'), true);

        if (empty($input)) {
            errorResponse('Data tidak valid');
            return;
        }

        $result = $this->model->update($id, $input);
        if ($result) {
            successResponse(null, 'Pinjaman berhasil diupdate');
        } else {
            errorResponse('Gagal mengupdate pinjaman', 500);
        }
    }

    // ===== DELETE =====
    public function destroy($id) {
        $result = $this->model->delete($id);
        if ($result) {
            successResponse(null, 'Pinjaman berhasil dihapus');
        } else {
            errorResponse('Gagal menghapus pinjaman', 500);
        }
    }

    // ===== UPDATE STATUS =====
    public function updateStatus($id, $input) {
        if (!isset($input['status'])) {
            errorResponse('Status wajib diisi');
            return;
        }

        $result = $this->model->updateStatus($id, $input['status']);
        if ($result) {
            successResponse(null, 'Status pinjaman berhasil diupdate');
        } else {
            errorResponse('Gagal update status', 500);
        }
    }

    // ===== HITUNG ANGSURAN =====
    public function hitungAngsuran() {
        $input = json_decode(file_get_contents('php://input'), true);

        if (!isset($input['jumlah']) || !isset($input['bunga']) || !isset($input['tenor'])) {
            errorResponse('Field wajib: jumlah, bunga, tenor');
            return;
        }

        $angsuran = $this->model->hitungAngsuran(
            $input['jumlah'],
            $input['bunga'],
            $input['tenor']
        );

        successResponse([
            'angsuran_per_bulan' => $angsuran,
            'total_harus_bayar' => $angsuran * $input['tenor']
        ]);
    }
}
?>
EOF