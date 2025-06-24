<?php
require_once '../../config/database.php';

if (!isset($_GET['user_id'])) {
    echo json_encode(['success' => false, 'message' => 'Missing user_id']);
    exit();
}

$user_id = intval($_GET['user_id']);

$stmt = $conn->prepare("SELECT * FROM tasks WHERE user_id = ?");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

$tasks = [];
while ($row = $result->fetch_assoc()) {
    $tasks[] = $row;
}

echo json_encode(['success' => true, 'tasks' => $tasks]);
?>
