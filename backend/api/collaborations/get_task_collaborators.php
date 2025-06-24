<?php
header('Content-Type: application/json');
require_once '../../config/database.php';

$task_id = isset($_GET['task_id']) ? intval($_GET['task_id']) : 0;
if (!$task_id) {
    echo json_encode(['success' => false, 'message' => 'Missing task_id']);
    exit;
}

// Get all accepted collaborators for all task_items under this task
$sql = "SELECT DISTINCT u.username
        FROM collaboration c
        JOIN task_item ti ON c.task_item_id = ti.id
        JOIN users u ON (u.id = c.collaborator_id OR u.id = c.requested_id)
        WHERE ti.task_id = ? AND c.status = 'accepted'";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $task_id);
$stmt->execute();
$result = $stmt->get_result();
$collaborators = [];
while ($row = $result->fetch_assoc()) {
    $collaborators[] = $row['username'];
}
$stmt->close();
$conn->close();

echo json_encode(['success' => true, 'collaborators' => $collaborators]);