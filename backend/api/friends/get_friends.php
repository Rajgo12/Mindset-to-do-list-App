<?php
require_once '../../config/database.php';
header('Content-Type: application/json');

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;

    if (!$user_id) {
        echo json_encode(['success' => false, 'message' => 'Missing user_id']);
        exit();
    }

    // Get all friends where user is either user1_id or user2_id
    $stmt = $conn->prepare("
        SELECT u.id, u.username, u.email
        FROM friends f
        JOIN users u ON (u.id = CASE WHEN f.user1_id = ? THEN f.user2_id ELSE f.user1_id END)
        WHERE f.user1_id = ? OR f.user2_id = ?
    ");
    $stmt->bind_param("iii", $user_id, $user_id, $user_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $friends = [];
    while ($row = $result->fetch_assoc()) {
        $friends[] = $row;
    }
    $stmt->close();

    echo json_encode($friends);
    exit();
}

echo json_encode(['success' => false, 'message' => 'Invalid request method']);
$conn->close();
?>
