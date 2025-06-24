<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

require_once '../../config/database.php';

// Optional: Show errors during development
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["emailFound" => false, "message" => "Method not allowed"]);
    exit();
}

$email = isset($_POST['email']) ? trim($_POST['email']) : '';

if (empty($email)) {
    http_response_code(400);
    echo json_encode(["emailFound" => false, "message" => "Email not provided"]);
    exit();
}

$stmt = $conn->prepare("SELECT id FROM users WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    http_response_code(200);
    echo json_encode(["emailFound" => true]);
} else {
    http_response_code(200);
    echo json_encode(["emailFound" => false]);
}

$stmt->close();
$conn->close();
?>
