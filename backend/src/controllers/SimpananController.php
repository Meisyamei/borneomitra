<?php
// src/controllers/SimpananController.php

require_once __DIR__ . '/../models/Simpanan.php';

class SimpananController {
    private $model;

    public function __construct() {
        $this->model = new Simpanan();
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
            errorResponse('Simpanan tidak ditemukan', 404);
        }
    }

    // ===== GET BY ANGGOTA =====
    public function byAnggota($anggotaId) {
        $data = $this->model->getByAnggota($anggotaId);
        successResponse($data);
    }

    // ===== TOTAL BY ANGGOTA =====
    public function totalByAnggota($anggotaId) {
        $total = $this->model->getTotalByAnggota($anggotaId);
        successResponse(['total' => $total]);
    }

    // ===== TOTAL ALL =====
    public function totalAll() {
        $total = $this->model->getTotalAll();
        successResponse(['total' => $total]);
    }

    // ===== BY PERIODE =====
    public function byPeriode($start, $end) {
        if (!$start || !$end) {
            errorResponse('Tanggal mulai dan akhir wajib diisi');
            return;
        }
        $data = $this->model->getByPeriode($start, $end);
        successResponse($data);
    }

    // ===== CREATE =====
    public function store() {
        $input = getInput();

        if (!validateRequired($input, ['anggota_id', 'nominal', 'jenis'])) {
            return;
        }

        $input['tipe'] = $input['tipe'] ?? 'masuk';
        $id = $this->model->create($input);

        if ($id) {
            // Update total simpanan anggota
            require_once __DIR__ . '/../models/Anggota.php';
            $anggota = new Anggota();
            $nominal = $input['tipe'] === 'masuk' ? $input['nominal'] : -$input['nominal'];
            $anggota->updateTotalSimpanan($input['anggota_id'], $nominal);

            successResponse(['id' => $id], 'Simpanan berhasil ditambahkan');
        } else {
            errorResponse('Gagal menambahkan simpanan', 500);
        }
    }

    // ===== TARIK SIMPANAN =====
    public function tarik() {
        $input = getInput();

        if (!validateRequired($input, ['anggota_id', 'nominal'])) {
            return;
        }

        // Cek saldo
        $saldo = $this->model->getTotalByAnggota($input['anggota_id']);
        if ($input['nominal'] > $saldo) {
            errorResponse('Saldo tidak mencukupi');
            return;
        }

        // Catat sebagai transaksi keluar
        $data = [
            'anggota_id' => $input['anggota_id'],
            'jenis' => 'sukarela',
            'tipe' => 'keluar',
            'nominal' => $input['nominal'],
            'tanggal' => date('Y-m-d'),
            'keterangan' => $input['keterangan'] ?? 'Penarikan simpanan',
        ];

        $id = $this->model->create($data);

        if ($id) {
            // Update total simpanan anggota
            require_once __DIR__ . '/../models/Anggota.php';
            $anggota = new Anggota();
            $anggota->updateTotalSimpanan($input['anggota_id'], -$input['nominal']);

            successResponse(['id' => $id], 'Penarikan berhasil');
        } else {
            errorResponse('Gagal melakukan penarikan', 500);
        }
    }
}
?>