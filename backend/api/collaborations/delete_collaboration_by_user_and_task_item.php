<?php
header('Content-Type: application/json');
require_once '../../config/database.php';

$user_id = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;
$task_item_id = isset($_POST['task_item_id']) ? intval($_POST['task_item_id']) : 0;
$target_user_id = isset($_POST['target_user_id']) ? intval($_POST['target_user_id']) : 0; // NEW

if (!$user_id || !$task_item_id) {
    echo json_encode(['success' => false, 'message' => 'Missing user_id or task_item_id']);
    exit;
}

// Get the owner of the task for this task_item
$owner_sql = "SELECT t.user_id AS owner_id
              FROM task_item ti
              JOIN tasks t ON ti.task_id = t.id
              WHERE ti.id = ?";
$owner_stmt = $conn->prepare($owner_sql);
$owner_stmt->bind_param("i", $task_item_id);
$owner_stmt->execute();
$owner_stmt->bind_result($owner_id);
$owner_stmt->fetch();
$owner_stmt->close();

if ($user_id == $owner_id && $target_user_id) {
    // Owner removes a collaborator
    $sql = "DELETE FROM collaboration WHERE requested_id = ? AND task_item_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ii", $target_user_id, $task_item_id);
} else {
    // User removes themselves
    $sql = "DELETE FROM collaboration WHERE requested_id = ? AND task_item_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ii", $user_id, $task_item_id);
}

$success = $stmt->execute();
$stmt->close();
$conn->close();

echo json_encode(['success' => $success]);