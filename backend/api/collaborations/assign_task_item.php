<?php
header('Content-Type: application/json; charset=utf-8');
ini_set('display_errors', 1);
ini_set('html_errors', 0);
error_reporting(E_ALL);

require_once '../../config/database.php';

// Handle input: JSON or POST fallback
$input = file_get_contents("php://input");
$data = json_decode($input, true);

$task_item_id = $data['task_item_id'] ?? $_POST['task_item_id'] ?? null;
$assigned_user_id = $data['assigned_user_id'] ?? $_POST['assigned_user_id'] ?? null;
$sender_id = $data['sender_id'] ?? $_POST['sender_id'] ?? null;

if (!$task_item_id || !$assigned_user_id || !$sender_id) {
    echo json_encode(['success' => false, 'message' => 'Missing parameters: task_item_id, assigned_user_id, or sender_id']);
    exit;
}

$task_item_id = intval($task_item_id);
$assigned_user_id = intval($assigned_user_id);
$sender_id = intval($sender_id);

try {
    // 1. Check if collaboration request already exists
    $checkSql = "SELECT id FROM collaboration 
                 WHERE task_item_id = ? AND collaborator_id = ? AND requested_id = ? AND status = 'pending'";
    $stmt = $pdo->prepare($checkSql);
    $stmt->execute([$task_item_id, $sender_id, $assigned_user_id]);
    $existing = $stmt->fetch();

    if ($existing) {
        echo json_encode(['success' => false, 'message' => 'Collaboration request already sent for this task item']);
        exit;
    }

    // 2. Insert collaboration request (status is pending by default)
    $insertSql = "INSERT INTO collaboration (collaborator_id, requested_id, task_item_id) VALUES (?, ?, ?)";
    $insertStmt = $pdo->prepare($insertSql);
    $insertStmt->execute([$sender_id, $assigned_user_id, $task_item_id]);

    echo json_encode(['success' => true, 'message' => 'Collaboration request sent successfully']);
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}
