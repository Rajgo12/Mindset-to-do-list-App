<?php
header('Content-Type: application/json');
require_once '../../config/database.php';

$task_item_id = isset($_POST['task_item_id']) ? intval($_POST['task_item_id']) : 0;
$requested_id = isset($_POST['requested_id']) ? intval($_POST['requested_id']) : 0;
$is_finished = isset($_POST['is_finished']) ? intval($_POST['is_finished']) : 1;
$user_id = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;

if (!$task_item_id || !$requested_id || !isset($_POST['is_finished']) || !$user_id) {
    echo json_encode(['success' => false, 'message' => 'Missing parameters']);
    exit;
}

// Get the owner of the task for this task_item
$owner_sql = "SELECT t.user_id FROM tasks t JOIN task_item ti ON t.id = ti.task_id WHERE ti.id = ?";
$owner_stmt = $conn->prepare($owner_sql);
$owner_stmt->bind_param("i", $task_item_id);
$owner_stmt->execute();
$owner_stmt->bind_result($owner_id);
$owner_stmt->fetch();
$owner_stmt->close();

// Allow:
// - The owner to check/uncheck any collaborator
// - The collaborator to check themselves
$allowed = false;
if ($user_id == $owner_id || ($is_finished == 1 && $user_id == $requested_id)) {
    $allowed = true;
}

if (!$allowed) {
    echo json_encode(['success' => false, 'message' => 'Not allowed']);
    exit;
}

$sql = "UPDATE collaboration SET is_finished = ? WHERE task_item_id = ? AND requested_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("iii", $is_finished, $task_item_id, $requested_id);
$success = $stmt->execute();
$stmt->close();

// --- REMOVE AUTO-FINISH LOGIC ---
// Do NOT auto-update task_item.is_completed here.
// Only the owner, via the Finish button, should mark the task as completed.

// --- REMOVE AUTO-UNFINISH LOGIC ---
// Do NOT auto-unfinish the task here either.

$conn->close();

echo json_encode(['success' => $success]);