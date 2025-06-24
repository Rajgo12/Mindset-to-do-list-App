<?php
header('Content-Type: application/json; charset=utf-8');
require_once '../../config/database.php';

$user_id = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;
$task_id = isset($_POST['task_id']) ? intval($_POST['task_id']) : 0;

if (!$user_id || !$task_id) {
    echo json_encode(['success' => false, 'message' => 'Missing parameters']);
    exit;
}

$stmt = $conn->prepare("DELETE FROM collaboration WHERE task_item_id IN (SELECT id FROM task_item WHERE task_id = ?) AND (collaborator_id = ? OR requested_id = ?)");
$stmt->bind_param("iii", $task_id, $user_id, $user_id);
$success = $stmt->execute();
$stmt->close();
$conn->close();

echo json_encode(['success' => $success]);
exit;