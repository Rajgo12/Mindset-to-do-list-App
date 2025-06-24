<?php
require_once '../../config/database.php';

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->note_id)) {
    echo json_encode(['success' => false, 'message' => 'Missing note_id']);
    exit();
}

$note_id = $data->note_id;

$stmt = $conn->prepare("DELETE FROM notes WHERE id = ?");
$stmt->bind_param("i", $note_id);

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Note deleted successfully']);
} else {
    echo json_encode(['success' => false, 'message' => 'Failed to delete note']);
}
?>