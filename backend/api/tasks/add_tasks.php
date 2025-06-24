<?php
header('Content-Type: application/json; charset=utf-8');

// Disable HTML error output
ini_set('display_errors', 1);
ini_set('html_errors', 0);
error_reporting(E_ALL);

require_once '../../config/database.php';

// Get raw input and decode
$input = file_get_contents("php://input");
$data = json_decode($input);

// Validate input
if (!isset($data->user_id) || !isset($data->title)) {
    echo json_encode(['success' => false, 'message' => 'Missing required fields']);
    exit;
}

$user_id = intval($data->user_id);
$title = trim($data->title);

// Prepare query (no description or due_date)
$stmt = $conn->prepare("INSERT INTO tasks (user_id, title) VALUES (?, ?)");
if (!$stmt) {
    echo json_encode(['success' => false, 'message' => 'Prepare failed: ' . $conn->error]);
    exit;
}
$stmt->bind_param("is", $user_id, $title);

// Execute
if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Task added successfully']);
} else {
    echo json_encode(['success' => false, 'message' => 'Execute failed: ' . $stmt->error]);
}

// Cleanup
$stmt->close();
$conn->close();
exit;