<?php
require_once '../../config/database.php';

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->reminder_id)) {
    echo json_encode(['success' => false, 'message' => 'Missing reminder_id']);
    exit();
}

$reminder_id = $data->reminder_id;

$stmt = $conn->prepare("DELETE FROM reminders WHERE id = ?");
$stmt->bind_param("i", $reminder_id);

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Reminder deleted successfully']);
} else {
    echo json_encode(['success' => false, 'message' => 'Failed to delete reminder']);
}
?>