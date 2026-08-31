<?php
// src/config/database.php
// Konfigurasi koneksi database

// ===== AMBIL ENV VARIABLE =====
$host = getenv('DB_HOST') ?: 'db_backend';
$dbname = getenv('DB_NAME') ?: 'koperasi';
$username = getenv('DB_USER') ?: 'koperasi';
$password = getenv('DB_PASSWORD') ?: 'p455w0rd1!.';

// ===== KONEKSI DATABASE =====
try {
    $pdo = new PDO(
        "mysql:host=$host;dbname=$dbname;charset=utf8mb4",
        $username,
        $password,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]
    );
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Database connection failed: ' . $e->getMessage()
    ]);
    exit;
}

// ===== FUNGSI RESPONSE =====
function jsonResponse($data, $statusCode = 200) {
    http_response_code($statusCode);
    header('Content-Type: application/json');
    echo json_encode($data, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    exit;
}

function successResponse($data = null, $message = 'Success') {
    jsonResponse([
        'status' => 'success',
        'message' => $message,
        'data' => $data
    ]);
}

function errorResponse($message, $statusCode = 400) {
    jsonResponse([
        'status' => 'error',
        'message' => $message
    ], $statusCode);
}

// ===== FUNGSI HELPER =====
function getInput() {
    $input = json_decode(file_get_contents('php://input'), true);
    return $input ?? [];
}

function validateRequired($data, $fields) {
    $missing = [];
    foreach ($fields as $field) {
        if (!isset($data[$field]) || empty($data[$field])) {
            $missing[] = $field;
        }
    }
    if (!empty($missing)) {
        errorResponse('Field wajib diisi: ' . implode(', ', $missing));
        return false;
    }
    return true;
}

function escapeString($str) {
    return htmlspecialchars(strip_tags(trim($str)));
}

function formatDate($date) {
    return date('Y-m-d', strtotime($date));
}
?>