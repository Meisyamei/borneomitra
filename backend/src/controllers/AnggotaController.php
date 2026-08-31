<?php
// src/controllers/AnggotaController.php

require_once __DIR__ . '/../models/Anggota.php';

class AnggotaController {
    private $model;

    public function __construct() {
        $this->model = new Anggota();
    }

    // ===== GET ALL =====
    public function index() {
        $limit = $_GET['limit'] ?? null;
        $data = $this->model->getAll($limit);
        successResponse($data);
    }

    // ===== GET BY ID =====
    public function show($id) {
        $data = $this->model->getById($id);
        if ($data) {
            successResponse($data);
        } else {
            errorResponse('Anggota tidak ditemukan', 404);
        }
    }

    // ===== SEARCH =====
    public function search($keyword) {
        if (empty($keyword)) {
            $this->index();
            return;
        }
        $data = $this->model->search($keyword);
        successResponse($data);
    }

    // ===== CREATE =====
    public function store() {
        $input = getInput();

        if (!validateRequired($input, ['nik', 'nama'])) {
            return;
        }

        // Cek duplikat NIK
        $existing = $this->model->getByNik($input['nik']);
        if ($existing) {
            errorResponse('NIK sudah terdaftar', 409);
            return;
        }

        $id = $this->model->create($input);
        if ($id) {
            successResponse(['id' => $id], 'Anggota berhasil ditambahkan');
        } else {
            errorResponse('Gagal menambahkan anggota', 500);
        }
    }

    // ===== UPDATE =====
    public function update($id) {
        $input = getInput();

        if (empty($input)) {
            errorResponse('Data tidak valid');
            return;
        }

        $result = $this->model->update($id, $input);
        if ($result) {
            successResponse(null, 'Anggota berhasil diupdate');
        } else {
            errorResponse('Gagal mengupdate anggota', 500);
        }
    }

    // ===== DELETE =====
    public function destroy($id) {
        $result = $this->model->delete($id);
        if ($result) {
            successResponse(null, 'Anggota berhasil dihapus');
        } else {
            errorResponse('Gagal menghapus anggota', 500);
        }
    }

    // ===== TOTAL =====
    public function total() {
        $total = $this->model->getTotal();
        successResponse(['total' => $total]);
    }
}
?>