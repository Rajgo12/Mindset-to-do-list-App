<?php
require_once '../../config/database.php';

// Get the JSON body
$data = json_decode(file_get_contents("php://input"), true);

// Validate required fields
if (!isset($data['user_id'], $data['title'], $data['reminder_time'])) {
    echo json_encode(['success' => false, 'message' => 'Missing required fields']);
    exit();
}

$user_id = intval($data['user_id']);
$title = trim($data['title']);
$reminder_time = trim($data['reminder_time']);

// Optional: Validate date format (YYYY-MM-DD HH:MM:SS)
if (!DateTime::createFromFormat('Y-m-d H:i:s', $reminder_time)) {
    echo json_encode(['success' => false, 'message' => 'Invalid date format. Use Y-m-d H:i:s']);
    exit();
}

// Prepare the SQL statement
$stmt = $conn->prepare("INSERT INTO reminders (user_id, title, reminder_time) VALUES (?, ?, ?)");
if (!$stmt) {
    echo json_encode(['success' => false, 'message' => 'Database error: Failed to prepare statement']);
    exit();
}

// Bind parameters and execute
$stmt->bind_param("iss", $user_id, $title, $reminder_time);

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Reminder added successfully']);
} else {
    echo json_encode(['success' => false, 'message' => 'Database error: Failed to add reminder']);
}

$stmt->close();
$conn->close();
?>
