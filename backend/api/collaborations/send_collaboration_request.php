<?php
header('Content-Type: application/json; charset=utf-8');
require_once '../../config/database.php';

// Get POST data
$task_item_id = isset($_POST['task_item_id']) ? intval($_POST['task_item_id']) : null;
$friend_ids_json = isset($_POST['friend_ids']) ? $_POST['friend_ids'] : null;
$owner_id = isset($_POST['owner_id']) ? intval($_POST['owner_id']) : null; // The owner/sender

if (!$task_item_id || !$friend_ids_json || !$owner_id) {
    echo json_encode(['success' => false, 'message' => 'Missing parameters']);
    exit;
}

$friend_ids = json_decode($friend_ids_json, true);
if (!is_array($friend_ids) || empty($friend_ids)) {
    echo json_encode(['success' => false, 'message' => 'Invalid friend_ids']);
    exit;
}

$success = true;
$alreadyInvited = [];
$invited = [];
$dbError = false;

foreach ($friend_ids as $friend_id) {
    // Check if a pending request already exists
    $check = $conn->prepare("SELECT id FROM collaboration WHERE task_item_id = ? AND collaborator_id = ? AND requested_id = ? AND status = 'pending'");
    if (!$check) {
        $dbError = true;
        break;
    }
    $check->bind_param("iii", $task_item_id, $owner_id, $friend_id);
    $check->execute();
    $check->store_result();
    if ($check->num_rows > 0) {
        $alreadyInvited[] = $friend_id;
        $check->close();
        continue; // Skip if already requested
    }
    $check->close();

    $stmt = $conn->prepare("INSERT INTO collaboration (collaborator_id, requested_id, task_item_id, status) VALUES (?, ?, ?, 'pending')");
    if (!$stmt) {
        $dbError = true;
        break;
    }
    $stmt->bind_param("iii", $owner_id, $friend_id, $task_item_id);
    if ($stmt->execute()) {
        $invited[] = $friend_id;
    } else {
        $dbError = true;
        $stmt->close();
        break;
    }
    $stmt->close();
}

$message = '';
if ($dbError) {
    $message = 'A database error occurred. Please try again.';
    $success = false;
} else if (!empty($alreadyInvited) && !empty($invited)) {
    $message = 'Some users were already invited and were skipped. Collaboration request sent successfully to others.';
} else if (!empty($alreadyInvited) && empty($invited)) {
    $message = 'All selected users have already been invited to collaborate on this task item.';
    $success = false;
} else if (!empty($invited)) {
    $message = 'Collaboration request sent successfully.';
} else {
    $message = 'No collaboration requests were sent.';
    $success = false;
}

echo json_encode([
    'success' => $success && !empty($invited),
    'already_invited' => $alreadyInvited,
    'invited' => $invited,
    'message' => $message
]);
$conn->close();
exit;