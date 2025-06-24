<?php
require_once '../../config/database.php';

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->task_id)) {
    echo json_encode(['success' => false, 'message' => 'Missing task_id']);
    exit();
}

$task_id = intval($data->task_id);

$stmt = $conn->prepare("DELETE FROM tasks WHERE id = ?");
$stmt->bind_param("i", $task_id);

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Task deleted successfully']);
} else {
    echo json_encode(['success' => false, 'message' => 'Failed to delete task']);
}
?>
