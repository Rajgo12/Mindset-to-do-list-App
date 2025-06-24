<?php
header('Content-Type: application/json');
require_once '../../config/database.php';

$task_id = isset($_GET['task_id']) ? intval($_GET['task_id']) : 0;
$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
$status = isset($_GET['status']) ? $_GET['status'] : 'accepted';

if (!$task_id || !$user_id) {
    echo json_encode(['success' => false, 'message' => 'Missing task_id or user_id']);
    exit;
}

// Get the owner of the task
$owner_sql = "SELECT user_id FROM tasks WHERE id = ?";
$owner_stmt = $conn->prepare($owner_sql);
$owner_stmt->bind_param("i", $task_id);
$owner_stmt->execute();
$owner_stmt->bind_result($owner_id);
$owner_stmt->fetch();
$owner_stmt->close();

if ($owner_id == $user_id) {
    // Owner: show only task_items that are being collaborated (have at least one collaboration)
    $sql = "SELECT DISTINCT ti.id, ti.title, ti.deadline, ti.is_completed, t.user_id AS owner_id
            FROM task_item ti
            JOIN tasks t ON ti.task_id = t.id
            JOIN collaboration c ON c.task_item_id = ti.id
            WHERE ti.task_id = ?
              AND c.status = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("is", $task_id, $status);
} else {
    // Collaborator: show only assigned task_items, include owner_id in each row
    $sql = "SELECT DISTINCT ti.id, ti.title, ti.deadline, ti.is_completed, t.user_id AS owner_id
            FROM task_item ti
            JOIN tasks t ON ti.task_id = t.id
            JOIN collaboration c ON c.task_item_id = ti.id
            WHERE ti.task_id = ? 
              AND (c.requested_id = ? OR c.collaborator_id = ?)
              AND c.status = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("iiis", $task_id, $user_id, $user_id, $status);
}

$stmt->execute();
$result = $stmt->get_result();
$items = [];
while ($row = $result->fetch_assoc()) {
    $row['assigned_users'] = [];
    // Get all assigned users for this task item (for display)
    $sql2 = "SELECT c.requested_id AS assigned_to, u.username AS assigned_to_name, c.is_finished
             FROM collaboration c
             LEFT JOIN users u ON c.requested_id = u.id
             WHERE c.task_item_id = ? AND c.status = ?";
    $stmt2 = $conn->prepare($sql2);
    $stmt2->bind_param("is", $row['id'], $status);
    $stmt2->execute();
    $result2 = $stmt2->get_result();
    while ($user = $result2->fetch_assoc()) {
        $row['assigned_users'][] = $user;
    }
    $stmt2->close();
    $items[] = $row;
}
$stmt->close();
$conn->close();

echo json_encode(['success' => true, 'owner_id' => $owner_id, 'items' => $items]);