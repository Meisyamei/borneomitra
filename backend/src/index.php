<?php
// ~/koperasi/backend/src/index.php
// Entry point utama - redirect ke API

error_reporting(E_ALL);
ini_set('display_errors', 1);

// ===== HEADERS =====
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// ===== HANDLE OPTIONS =====
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

// ===== REDIRECT KE API =====
$requestUri = $_SERVER['REQUEST_URI'];

// Cek apakah request ke /api
if (strpos($requestUri, '/api') === 0 || strpos($requestUri, '/api/') === 0) {
    // Redirect ke index.php di folder api
    require_once __DIR__ . '/api/index.php';
    exit;
}

// ===== ROOT =====
if ($requestUri === '/' || $requestUri === '/index.php') {
    echo json_encode([
        'status' => 'success',
        'message' => 'Koperasi BMS API v1.0',
        'version' => '1.0.0',
        'api' => '/api',
        'documentation' => 'https://github.com/your-repo/bmss-api',
        'endpoints' => [
            'anggota' => '/api/anggota',
            'simpanan' => '/api/simpanan',
            'pinjaman' => '/api/pinjaman',
            'angsuran' => '/api/angsuran',
            'laporan' => '/api/laporan',
            'dashboard' => '/api/dashboard',
            'auth' => '/api/auth/login',
        ]
    ], JSON_PRETTY_PRINT);
    exit;
}

// ===== 404 =====
http_response_code(404);
echo json_encode([
    'status' => 'error',
    'message' => 'Route not found'
]);
?>