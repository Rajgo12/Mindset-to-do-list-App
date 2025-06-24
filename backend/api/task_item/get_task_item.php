<?php
header('Content-Type: application/json; charset=utf-8');

// Show errors for debugging (remove in production)
ini_set('display_errors', 1);
ini_set('html_errors', 0);
error_reporting(E_ALL);

require_once '../../config/database.php';

// Handle input: try JSON first, else fallback to POST form data
$input = file_get_contents("php://input");
$data = json_decode($input);

if ($data === null) {
    // fallback: use $_POST
    $task_id = isset($_POST['task_id']) ? $_POST['task_id'] : null;
} else {
    $task_id = isset($data->task_id) ? $data->task_id : null;
}

// Validate task_id
if (empty($task_id) || !is_numeric($task_id)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Missing or invalid task_id'
    ]);
    exit;
}

$task_id = intval($task_id);

// Prepare statement
$stmt = $conn->prepare("SELECT * FROM task_item WHERE task_id = ?");
if (!$stmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Prepare failed: ' . $conn->error
    ]);
    exit;
}

$stmt->bind_param("i", $task_id);

if (!$stmt->execute()) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Execute failed: ' . $stmt->error
    ]);
    exit;
}

$result = $stmt->get_result();
$items = [];

while ($row = $result->fetch_assoc()) {
    // Keep is_completed as string '0' or '1' to match Flutter expectations
    $row['is_completed'] = (string) $row['is_completed'];
    $items[] = $row;
}

// Success response
echo json_encode([
    'success' => true,
    'task_items' => $items
]);

$stmt->close();
$conn->close();
exit;
