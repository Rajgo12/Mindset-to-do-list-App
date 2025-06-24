<?php
require_once '../../config/database.php';

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->task_id) || !isset($data->owner_id) || !isset($data->collaborator_id)) {
    echo json_encode(['success' => false, 'message' => 'Missing required fields']);
    exit();
}

$task_id = $data->task_id;
$owner_id = $data->owner_id;
$collaborator_id = $data->collaborator_id;

$stmt = $conn->prepare("INSERT INTO collaborations (task_id, owner_id, collaborator_id) VALUES (?, ?, ?)");
$stmt->bind_param("iii", $task_id, $owner_id, $collaborator_id);

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Collaboration added successfully']);
} else {
    echo json_encode(['success' => false, 'message' => 'Failed to add collaboration']);
}
?>