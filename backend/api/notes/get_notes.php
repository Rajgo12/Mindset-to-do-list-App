<?php
require_once '../../config/database.php';

// Use POST instead of GET
if (!isset($_POST['user_id'])) {
    echo json_encode(['success' => false, 'message' => 'User ID required']);
    exit();
}

$user_id = $_POST['user_id'];

$stmt = $conn->prepare("SELECT id, user_id, title, content, created_at, updated_at FROM notes WHERE user_id = ? ORDER BY updated_at DESC");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

$notes = [];
while ($row = $result->fetch_assoc()) {
    $notes[] = $row;
}

echo json_encode(['success' => true, 'notes' => $notes]);
?>
