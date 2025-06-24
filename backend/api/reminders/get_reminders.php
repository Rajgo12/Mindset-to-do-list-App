<?php
header('Content-Type: application/json; charset=utf-8');
require_once '../../config/database.php';

// Get user_id from query parameter
$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;

if ($user_id <= 0) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Invalid or missing user_id"]);
    exit;
}

// SQL to get reminders for this user
$sql = "
    SELECT 
        r.id, 
        r.task_item_id, 
        r.title, 
        r.reminder_time, 
        ti.is_completed
    FROM reminders r
    INNER JOIN task_item ti ON r.task_item_id = ti.id
    INNER JOIN tasks t ON ti.task_id = t.id
    WHERE t.user_id = ?
    ORDER BY r.reminder_time ASC
";

$stmt = $conn->prepare($sql);
if (!$stmt) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Prepare failed: " . $conn->error]);
    exit;
}

$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

$reminders = [];
while ($row = $result->fetch_assoc()) {
    $reminders[] = $row;
}

$stmt->close();
$conn->close();

echo json_encode([
    "success" => true,
    "reminders" => $reminders
]);