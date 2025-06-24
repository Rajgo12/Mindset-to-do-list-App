<?php
require_once '../../config/database.php';

$id = isset($_POST['collaboration_id']) ? intval($_POST['collaboration_id']) : 0;
$status = isset($_POST['status']) ? $_POST['status'] : '';

if (!$id || !$status) {
    echo json_encode(['success' => false, 'message' => 'Missing parameters']);
    exit;
}

if ($status === 'accepted') {
    $sql = "UPDATE collaboration SET status = 'accepted' WHERE id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $id);
    $success = $stmt->execute();
    $stmt->close();
    echo json_encode(['success' => $success]);
} elseif ($status === 'rejected') {
    $sql = "DELETE FROM collaboration WHERE id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $id);
    $success = $stmt->execute();
    $stmt->close();
    echo json_encode(['success' => $success]);
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid status']);
}

$conn->close();