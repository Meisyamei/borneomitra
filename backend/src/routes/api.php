<?php
// src/routes/api.php
// Router untuk semua API endpoint

require_once __DIR__ . '/../config/database.php';

// ===== AMBIL URL DAN METHOD =====
$requestUri = $_SERVER['REQUEST_URI'];
$requestMethod = $_SERVER['REQUEST_METHOD'];

// Parse URL: hapus base path /api
$path = parse_url($requestUri, PHP_URL_PATH);
$path = str_replace('/api', '', $path);
$path = trim($path, '/');
$segments = explode('/', $path);

// ===== ROOT API =====
if (empty($segments[0])) {
    successResponse([
        'message' => 'Koperasi BMS API v1.0',
        'endpoints' => [
            'anggota' => '/api/anggota',
            'simpanan' => '/api/simpanan',
            'pinjaman' => '/api/pinjaman',
            'angsuran' => '/api/angsuran',
        ]
    ]);
    return;
}

// ===== ROUTING =====
$resource = $segments[0];
$id = $segments[1] ?? null;
$action = $segments[1] ?? null;

// ===== LOAD CONTROLLERS =====
$controllerPath = __DIR__ . '/../controllers/';

switch ($resource) {
    // ===== ANGGOTA =====
    case 'anggota':
        require_once $controllerPath . 'AnggotaController.php';
        $controller = new AnggotaController();

        if ($requestMethod === 'GET' && !$id) {
            $controller->index();
        } elseif ($requestMethod === 'GET' && $id && is_numeric($id)) {
            $controller->show($id);
        } elseif ($requestMethod === 'GET' && $action === 'search') {
            $keyword = $_GET['q'] ?? '';
            $controller->search($keyword);
        } elseif ($requestMethod === 'GET' && $action === 'total') {
            $controller->total();
        } elseif ($requestMethod === 'POST') {
            $controller->store();
        } elseif ($requestMethod === 'PUT' && $id && is_numeric($id)) {
            $controller->update($id);
        } elseif ($requestMethod === 'DELETE' && $id && is_numeric($id)) {
            $controller->destroy($id);
        } else {
            errorResponse('Method not allowed', 405);
        }
        break;

    // ===== SIMPANAN =====
    case 'simpanan':
        require_once $controllerPath . 'SimpananController.php';
        $controller = new SimpananController();

        if ($requestMethod === 'GET' && !$id) {
            $controller->index();
        } elseif ($requestMethod === 'GET' && $id && is_numeric($id)) {
            $controller->show($id);
        } elseif ($requestMethod === 'GET' && $action === 'anggota' && $id && is_numeric($id)) {
            $controller->byAnggota($id);
        } elseif ($requestMethod === 'GET' && $action === 'total' && $id && is_numeric($id)) {
            $controller->totalByAnggota($id);
        } elseif ($requestMethod === 'GET' && $action === 'total' && !$id) {
            $controller->totalAll();
        } elseif ($requestMethod === 'GET' && $action === 'periode') {
            $start = $_GET['start'] ?? null;
            $end = $_GET['end'] ?? null;
            $controller->byPeriode($start, $end);
        } elseif ($requestMethod === 'POST' && $action === 'tarik') {
            $controller->tarik();
        } elseif ($requestMethod === 'POST') {
            $controller->store();
        } else {
            errorResponse('Method not allowed', 405);
        }
        break;

    // ===== PINJAMAN =====
    case 'pinjaman':
        require_once $controllerPath . 'PinjamanController.php';
        $controller = new PinjamanController();

        if ($requestMethod === 'GET' && !$id) {
            $controller->index();
        } elseif ($requestMethod === 'GET' && $id && is_numeric($id)) {
            $controller->show($id);
        } elseif ($requestMethod === 'GET' && $action === 'anggota' && $id && is_numeric($id)) {
            $controller->byAnggota($id);
        } elseif ($requestMethod === 'GET' && $action === 'status' && $id) {
            $controller->byStatus($id);
        } elseif ($requestMethod === 'GET' && $action === 'hitung-angsuran') {
            $controller->hitungAngsuran();
        } elseif ($requestMethod === 'POST' && $action === 'hitung-angsuran') {
            $controller->hitungAngsuran();
        } elseif ($requestMethod === 'POST') {
            $controller->store();
        } elseif ($requestMethod === 'PUT' && $id && is_numeric($id) && $action === 'status') {
            $input = json_decode(file_get_contents('php://input'), true);
            $controller->updateStatus($id, $input);
        } elseif ($requestMethod === 'PUT' && $id && is_numeric($id)) {
            $controller->update($id);
        } elseif ($requestMethod === 'DELETE' && $id && is_numeric($id)) {
            $controller->destroy($id);
        } else {
            errorResponse('Method not allowed', 405);
        }
        break;

    // ===== ANGSURAN =====
    case 'angsuran':
        require_once $controllerPath . 'AngsuranController.php';
        $controller = new AngsuranController();

        if ($requestMethod === 'GET' && !$id) {
            $controller->index();
        } elseif ($requestMethod === 'GET' && $id && is_numeric($id)) {
            $controller->show($id);
        } elseif ($requestMethod === 'GET' && $action === 'pinjaman' && $id && is_numeric($id)) {
            $controller->byPinjaman($id);
        } elseif ($requestMethod === 'GET' && $action === 'tunggakan') {
            $controller->tunggakan();
        } elseif ($requestMethod === 'GET' && $action === 'jatuh-tempo-hari-ini') {
            $controller->jatuhTempoHariIni();
        } elseif ($requestMethod === 'GET' && $action === 'hampir-jatuh-tempo') {
            $controller->hampirJatuhTempo();
        } elseif ($requestMethod === 'POST' && $action === 'hitung-denda') {
            $input = json_decode(file_get_contents('php://input'), true);
            $controller->hitungDenda($input);
        } elseif ($requestMethod === 'POST' && $action === 'bayar' && $id && is_numeric($id)) {
            $input = json_decode(file_get_contents('php://input'), true);
            $controller->bayar($id, $input);
        } elseif ($requestMethod === 'POST') {
            $input = json_decode(file_get_contents('php://input'), true);
            $controller->store($input);
        } else {
            errorResponse('Method not allowed', 405);
        }
        break;

    // ===== DEFAULT =====
    default:
        errorResponse("Resource '$resource' tidak ditemukan", 404);
        break;
}
?>