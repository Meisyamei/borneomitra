cat > ~/koperasi/backend/src/api/index.php << 'EOF'
<?php
// ~/koperasi/backend/src/api/index.php
// Entry point API - semua request /api/* masuk ke sini

// ===== ERROR REPORTING =====
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', '/var/log/php_errors.log');

// ===== HEADERS =====
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, PATCH, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept");
header("Access-Control-Max-Age: 86400");

// ===== HANDLE PREFLIGHT =====
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

// ===== LOAD KONFIGURASI =====
require_once __DIR__ . '/../config/database.php';

// ===== AMBIL REQUEST =====
$requestUri = $_SERVER['REQUEST_URI'];
$requestMethod = $_SERVER['REQUEST_METHOD'];
$input = json_decode(file_get_contents('php://input'), true) ?? [];

// Parse URL - hapus /api prefix
$path = parse_url($requestUri, PHP_URL_PATH);
$path = preg_replace('#^/api#', '', $path);
$path = trim($path, '/');
$segments = explode('/', $path);

// ===== ROOT API =====
if (empty($segments[0])) {
    successResponse([
        'message' => 'Koperasi BMS API v1.0',
        'version' => '1.0.0',
        'endpoints' => [
            'anggota' => '/api/anggota',
            'simpanan' => '/api/simpanan',
            'pinjaman' => '/api/pinjaman',
            'angsuran' => '/api/angsuran',
        ]
    ]);
    exit;
}

// ===== ROUTING =====
$resource = $segments[0];
$id = $segments[1] ?? null;
$action = $segments[1] ?? null;

// ===== LOAD CONTROLLER =====
$controllerPath = __DIR__ . '/../controllers/';

switch ($resource) {
    // ========================================
    // 1. ANGGOTA
    // ========================================
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

    // ========================================
    // 2. SIMPANAN
    // ========================================
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
        } elseif ($requestMethod === 'POST' && $action === 'tarik') {
            $controller->tarik();
        } elseif ($requestMethod === 'POST') {
            $controller->store();
        } else {
            errorResponse('Method not allowed', 405);
        }
        break;

    // ========================================
    // 3. PINJAMAN
    // ========================================
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
        } elseif ($requestMethod === 'POST' && $action === 'hitung-angsuran') {
            $controller->hitungAngsuran();
        } elseif ($requestMethod === 'POST') {
            $controller->store();
        } elseif ($requestMethod === 'PUT' && $action === 'status' && $id && is_numeric($id)) {
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

    // ========================================
    // 4. ANGSURAN
    // ========================================
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

    // ========================================
    // 5. LAPORAN
    // ========================================
    case 'laporan':
        // Belum ada controller, response sementara
        successResponse(['message' => 'Laporan endpoint (belum diimplementasikan)']);
        break;

    // ========================================
    // 6. DASHBOARD
    // ========================================
    case 'dashboard':
        // Belum ada controller, response sementara
        successResponse(['message' => 'Dashboard endpoint (belum diimplementasikan)']);
        break;

    // ========================================
    // 7. AUTH
    // ========================================
    case 'auth':
        // Belum ada controller, response sementara
        successResponse(['message' => 'Auth endpoint (belum diimplementasikan)']);
        break;

    // ========================================
    // 8. NOTIFIKASI
    // ========================================
    case 'notifikasi':
        // Belum ada controller, response sementara
        successResponse(['message' => 'Notifikasi endpoint (belum diimplementasikan)']);
        break;

    // ========================================
    // 9. ARISAN
    // ========================================
    case 'arisan':
        // Belum ada controller, response sementara
        successResponse(['message' => 'Arisan endpoint (belum diimplementasikan)']);
        break;

    // ========================================
    // 10. PROFILE
    // ========================================
    case 'profile':
        // Belum ada controller, response sementara
        successResponse(['message' => 'Profile endpoint (belum diimplementasikan)']);
        break;

    // ========================================
    // 404 - ROUTE NOT FOUND
    // ========================================
    default:
        errorResponse("Resource '$resource' tidak ditemukan", 404);
        break;
}
?>
EOF