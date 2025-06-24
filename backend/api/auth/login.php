<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
require_once '../../config/database.php';

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->identifier) || !isset($data->password)) {
    echo json_encode(['success' => false, 'message' => 'Missing credentials']);
    exit();
}

$identifier = $data->identifier;
$password = $data->password;

// Prepare SQL to check both email and username
$stmt = $conn->prepare("SELECT id, username, email, password FROM users WHERE email = ? OR username = ?");
$stmt->bind_param("ss", $identifier, $identifier);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    if (password_verify($password, $row['password'])) {
        echo json_encode([
            'success' => true,
            'user' => [
                'id' => $row['id'],
                'username' => $row['username'],
                'email' => $row['email']
            ]
        ]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Invalid password']);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'User not found']);
}
?>
