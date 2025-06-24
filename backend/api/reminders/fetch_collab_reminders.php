<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
header('Content-Type: application/json; charset=utf-8');
require_once '../../config/database.php';

$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
if (!$user_id) {
    echo json_encode(['success' => false, 'message' => 'Missing user_id']);
    exit;
}

$sql = "
    SELECT ti.id, ti.title, ti.deadline, ti.is_completed, t.user_id AS owner_id
    FROM collaboration c
    JOIN task_item ti ON c.task_item_id = ti.id
    JOIN tasks t ON ti.task_id = t.id
    WHERE (c.collaborator_id = ? OR c.requested_id = ?)
      AND c.status = 'accepted'
";
$stmt = $conn->prepare($sql);
if (!$stmt) {
    echo json_encode(['success' => false, 'message' => 'DB prepare failed: ' . $conn->error]);
    exit;
}
$stmt->bind_param("ii", $user_id, $user_id);
$stmt->execute();
$result = $stmt->get_result();

$reminders = [];
while ($row = $result->fetch_assoc()) {
    $reminders[] = [
        'id' => $row['id'],
        'title' => $row['title'],
        'reminder_time' => $row['deadline'],
        'is_completed' => $row['is_completed'],
        'is_collab' => true,
        'owner_id' => $row['owner_id']
    ];
}
$stmt->close();

echo json_encode(['success' => true, 'reminders' => $reminders]);
exit;