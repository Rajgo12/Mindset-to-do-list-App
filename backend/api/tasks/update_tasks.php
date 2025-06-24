<?php
require_once '../../config/database.php';

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->task_id) || !isset($data->title)) {
    echo json_encode(['success' => false, 'message' => 'Missing required fields']);
    exit();
}

$task_id = intval($data->task_id);
$title = $data->title;

$stmt = $conn->prepare("UPDATE tasks SET title = ? WHERE id = ?");
$stmt->bind_param("si", $title, $task_id);

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Task updated successfully']);
} else {
    echo json_encode(['success' => false, 'message' => 'Failed to update task']);
}

$stmt->close();
$conn->close();
?>