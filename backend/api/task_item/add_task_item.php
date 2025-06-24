<?php
header('Content-Type: application/json; charset=utf-8');
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
    $title = isset($_POST['title']) ? $_POST['title'] : null;
    $deadline = isset($_POST['deadline']) && $_POST['deadline'] !== '' ? $_POST['deadline'] : null;
} else {
    $task_id = isset($data->task_id) ? $data->task_id : null;
    $title = isset($data->title) ? $data->title : null;
    $deadline = isset($data->deadline) && $data->deadline !== '' ? $data->deadline : null;
}

// Validate required fields
if (empty($task_id) || !is_numeric($task_id) || empty($title)) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Missing or invalid required fields: task_id or title"]);
    exit;
}

$task_id = intval($task_id);
$title = trim($title);
$deadline = $deadline !== null ? trim($deadline) : null;

// Step 1: Insert into task_item
if ($deadline === null) {
    $stmt = $conn->prepare("INSERT INTO task_item (task_id, title, deadline) VALUES (?, ?, NULL)");
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Prepare failed: " . $conn->error]);
        exit;
    }
    $stmt->bind_param("is", $task_id, $title);
} else {
    $stmt = $conn->prepare("INSERT INTO task_item (task_id, title, deadline) VALUES (?, ?, ?)");
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Prepare failed: " . $conn->error]);
        exit;
    }
    $stmt->bind_param("iss", $task_id, $title, $deadline);
}

if (!$stmt->execute()) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Execute failed: " . $stmt->error]);
    $stmt->close();
    $conn->close();
    exit;
}

$task_item_id = $stmt->insert_id;
$stmt->close();

// Step 2: Insert reminder if deadline is set
if ($deadline !== null) {
    $reminder_stmt = $conn->prepare("INSERT INTO reminders (task_item_id, title, reminder_time, is_completed) VALUES (?, ?, ?, 0)");
    if (!$reminder_stmt) {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Reminder prepare failed: " . $conn->error]);
        $conn->close();
        exit;
    }

    $reminder_stmt->bind_param("iss", $task_item_id, $title, $deadline);

    if (!$reminder_stmt->execute()) {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Reminder execute failed: " . $reminder_stmt->error]);
        $reminder_stmt->close();
        $conn->close();
        exit;
    }

    $reminder_stmt->close();
}

$conn->close();
echo json_encode(["success" => true, "message" => "Task item (and reminder if applicable) added successfully"]);
exit;
