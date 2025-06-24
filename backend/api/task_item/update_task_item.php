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
    $content = isset($_POST['content']) ? $_POST['content'] : null;
    $deadline = isset($_POST['deadline']) ? $_POST['deadline'] : null;
    $is_completed = isset($_POST['is_completed']) ? $_POST['is_completed'] : null;
} else {
    $id = $data->id ?? null;
    $content = property_exists($data, 'content') ? $data->content : null;
    $deadline = property_exists($data, 'deadline') ? $data->deadline : null;
    $is_completed = property_exists($data, 'is_completed') ? $data->is_completed : null;
}

// Validate ID
if (empty($id) || !is_numeric($id)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Missing or invalid task item id']);
    exit;
}
$id = intval($id);

$updates = [];
$params = [];
$types = "";

// Update only if fields are explicitly provided (even if empty string)
// For content: allow empty string as valid update
if ($content !== null) {
    $content = trim($content);
    $updates[] = "content = ?";
    $params[] = $content;
    $types .= "s";
}

// For deadline: allow NULL if empty string passed
if ($deadline !== null) {
    if ($deadline === '') {
        $updates[] = "deadline = NULL";
    } else {
        $deadline = trim($deadline);
        $updates[] = "deadline = ?";
        $params[] = $deadline;
        $types .= "s";
    }
}

// For is_completed: accept only 0 or 1 integers
if ($is_completed !== null) {
    $is_completed = (int)$is_completed;
    if ($is_completed !== 0 && $is_completed !== 1) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid is_completed value, must be 0 or 1']);
        exit;
    }
    $updates[] = "is_completed = ?";
    $params[] = $is_completed;
    $types .= "i";
}

if (count($updates) === 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Nothing to update']);
    exit;
}

// Start transaction so both updates succeed or fail together
$conn->begin_transaction();

// Update task_item table
$sql = "UPDATE task_item SET " . implode(", ", $updates) . " WHERE id = ?";
$params[] = $id;
$types .= "i";

$stmt = $conn->prepare($sql);
if (!$stmt) {
    $conn->rollback();
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Prepare failed: ' . $conn->error]);
    exit;
}

$stmt->bind_param($types, ...$params);
if (!$stmt->execute()) {
    $stmt->close();
    $conn->rollback();
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Execute failed: ' . $stmt->error]);
    exit;
}
$stmt->close();

// If is_completed was updated, also update reminders linked to this task item
if ($is_completed !== null) {
    $stmt2 = $conn->prepare("UPDATE reminders SET is_completed = ? WHERE task_item_id = ?");
    if (!$stmt2) {
        $conn->rollback();
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Prepare failed (reminders): ' . $conn->error]);
        exit;
    }
    $stmt2->bind_param("ii", $is_completed, $id);
    if (!$stmt2->execute()) {
        $stmt2->close();
        $conn->rollback();
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Execute failed (reminders): ' . $stmt2->error]);
        exit;
    }
    $stmt2->close();
}

$conn->commit();

echo json_encode(['success' => true, 'message' => 'Task item updated successfully']);
$conn->close();
exit;
