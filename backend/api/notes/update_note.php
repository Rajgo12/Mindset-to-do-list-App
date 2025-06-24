<?php
require_once '../../config/database.php';

// Read JSON input
$data = json_decode(file_get_contents("php://input"));

if (!isset($data->note_id) || !isset($data->title)) {
    echo json_encode(['success' => false, 'message' => 'Missing required fields']);
    exit();
}

$note_id = intval($data->note_id);
$title = trim($data->title);
$content = isset($data->content) ? trim($data->content) : '';

// Base64 encode the content before saving
$encodedContent = base64_encode($content);

// Prepare the UPDATE statement
$stmt = $conn->prepare("UPDATE notes SET title = ?, content = ?, updated_at = NOW() WHERE id = ?");
$stmt->bind_param("ssi", $title, $encodedContent, $note_id);

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Note updated successfully']);
} else {
    echo json_encode(['success' => false, 'message' => 'Failed to update note']);
}

$stmt->close();
$conn->close();
?>
