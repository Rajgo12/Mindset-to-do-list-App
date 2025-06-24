<?php
require_once '../../config/database.php';

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->user_id) || !isset($data->title)) {
    echo json_encode(['success' => false, 'message' => 'Missing required fields']);
    exit();
}

$user_id = $data->user_id;
$title = $data->title;
$content = $data->content ?? '';

// Encrypt the content using base64
$encodedContent = base64_encode($content);

$stmt = $conn->prepare("INSERT INTO notes (user_id, title, content) VALUES (?, ?, ?)");
$stmt->bind_param("iss", $user_id, $title, $encodedContent);

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Note added successfully']);
} else {
    echo json_encode(['success' => false, 'message' => 'Failed to add note']);
}
?>
