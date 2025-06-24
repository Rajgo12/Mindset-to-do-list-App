<?php
header('Content-Type: application/json; charset=utf-8');
ini_set('display_errors', 1);
ini_set('html_errors', 0);
error_reporting(E_ALL);

require_once '../../config/database.php';

// Get input from JSON or POST fallback
$input = file_get_contents("php://input");
$data = json_decode($input);

if ($data === null) {
    $id = $_POST['id'] ?? null;
    $user_id = $_POST['user_id'] ?? null;
    $is_completed = isset($_POST['is_completed']) ? $_POST['is_completed'] : null;
    $content = isset($_POST['content']) ? $_POST['content'] : null;
    $deadline = isset($_POST['deadline']) ? $_POST['deadline'] : null;
} else {
    $id = $data->id ?? null;
    $user_id = $data->user_id ?? null;
    $is_completed = property_exists($data, 'is_completed') ? $data->is_completed : null;
    $content = property_exists($data, 'content') ? $data->content : null;
    $deadline = property_exists($data, 'deadline') ? $data->deadline : null;
}

// Validate ID and user_id
if (empty($id) || !is_numeric($id) || empty($user_id) || !is_numeric($user_id)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Missing or invalid task item id or user id']);
    exit;
}
$id = intval($id);
$user_id = intval($user_id);

// Check if user is a collaborator for this task item and collaboration is accepted
$check = $conn->prepare("SELECT id FROM collaboration WHERE task_item_id = ? AND (collaborator_id = ? OR requested_id = ?) AND status = 'accepted'");
$check->bind_param("iii", $id, $user_id, $user_id);
$check->execute();
$check->store_result();
if ($check->num_rows === 0) {
    $check->close();
    http_response_code(403);
    echo json_encode(['success' => false, 'message' => 'You are not allowed to update this task item']);
    exit;
}
$check->close();

// --- ADD THIS SECTION: UPDATE LOGIC ---
if ($is_completed === null) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Missing is_completed value']);
    exit;
}

$stmt = $conn->prepare("UPDATE task_item SET is_completed = ? WHERE id = ?");
$stmt->bind_param("ii", $is_completed, $id);

if ($stmt->execute()) {
    echo json_encode(['success' => true]);
} else {
    echo json_encode(['success' => false, 'message' => 'Failed to update task item']);
}
$stmt->close();
$conn->close();
exit;