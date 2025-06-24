<?php
header('Content-Type: application/json; charset=utf-8');
require_once '../../config/database.php';

$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
if (!$user_id) {
    echo json_encode(['success' => false, 'message' => 'Missing user_id']);
    exit;
}

$sql = "SELECT ti.id, ti.title FROM task_item ti
        JOIN tasks t ON ti.task_id = t.id
        WHERE t.user_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

$items = [];
while ($row = $result->fetch_assoc()) {
    $items[] = $row;
}
$stmt->close();

echo json_encode(['success' => true, 'items' => $items]);
exit;