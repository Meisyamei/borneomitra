<?php
// src/controllers/AngsuranController.php

require_once __DIR__ . '/../models/Angsuran.php';

class AngsuranController {
    private $model;

    public function __construct() {
        $this->model = new Angsuran();
    }

    // ===== GET ALL =====
    public function index() {
        $pinjamanId = $_GET['pinjaman_id'] ?? null;
        $data = $this->model->getAll($pinjamanId);
        successResponse($data);
    }

    // ===== GET BY ID =====
    public function show($id) {
        $data = $this->model->getById($id);
        if ($data) {
            successResponse($data);
        } else {
            errorResponse('Angsuran tidak ditemukan', 404);
        }
    }

    // ===== GET BY PINJAMAN =====
    public function byPinjaman($pinjamanId) {
        $data = $this->model->getByPinjaman($pinjamanId);
        successResponse($data);
    }

    // ===== CREATE =====
    public function store($input) {
        if (!validateRequired($input, ['pinjaman_id', 'angsuran_ke', 'nominal', 'tanggal_jatuh_tempo'])) {
            return;
        }

        $id = $this->model->create($input);
        if ($id) {
            successResponse(['id' => $id], 'Angsuran berhasil ditambahkan');
        } else {
            errorResponse('Gagal menambahkan angsuran', 500);
        }
    }

    // ===== BAYAR =====
    public function bayar($id, $input) {
        $tanggalBayar = $input['tanggal_bayar'] ?? date('Y-m-d');

        try {
            $angsuran = $this->model->getById($id);
            if (!$angsuran) {
                errorResponse('Angsuran tidak ditemukan', 404);
                return;
            }

            // Hitung denda
            $denda = $this->model->hitungDenda(
                $angsuran['tanggal_jatuh_tempo'],
                $tanggalBayar
            );

            $result = $this->model->bayar($id, $tanggalBayar, $denda);

            if ($result) {
                successResponse([
                    'denda' => $denda,
                    'total_bayar' => $angsuran['nominal'] + $denda
                ], 'Pembayaran angsuran berhasil');
            } else {
                errorResponse('Gagal membayar angsuran', 500);
            }
        } catch (Exception $e) {
            errorResponse('Error: ' . $e->getMessage(), 500);
        }
    }

    // ===== TUNGGAKAN =====
    public function tunggakan() {
        $data = $this->model->getTunggakan();
        successResponse($data);
    }

    // ===== JATUH TEMPO HARI INI =====
    public function jatuhTempoHariIni() {
        $data = $this->model->getJatuhTempoHariIni();
        successResponse($data);
    }

    // ===== HAMPIR JATUH TEMPO =====
    public function hampirJatuhTempo() {
        $data = $this->model->getHampirJatuhTempo();
        successResponse($data);
    }

    // ===== HITUNG DENDA =====
    public function hitungDenda($input) {
        if (!validateRequired($input, ['tanggal_jatuh_tempo', 'tanggal_bayar'])) {
            return;
        }

        $denda = $this->model->hitungDenda(
            $input['tanggal_jatuh_tempo'],
            $input['tanggal_bayar']
        );

        successResponse(['denda' => $denda]);
    }
}
?>