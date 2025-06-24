<?php
require_once '../../config/database.php';

// Get JSON input
$data = json_decode(file_get_contents("php://input"));

// Validate required fields
if (!isset($data->user_id) || !isset($data->friend_id)) {
    echo json_encode(['success' => false, 'message' => 'Missing required fields']);
    exit();
}

$user_id = (int)$data->user_id;
$friend_id = (int)$data->friend_id;

if ($user_id === $friend_id) {
    echo json_encode(['success' => false, 'message' => 'Cannot add yourself as friend']);
    exit();
}

// Check if users are already friends
$stmt = $conn->prepare("
    SELECT id FROM friends 
    WHERE (user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?)
");
$stmt->bind_param("iiii", $user_id, $friend_id, $friend_id, $user_id);
$stmt->execute();
$stmt->store_result();

if ($stmt->num_rows > 0) {
    echo json_encode(['success' => false, 'message' => 'You are already friends']);
    $stmt->close();
    $conn->close();
    exit();
}
$stmt->close();

// Check if a friend request already exists (pending or accepted)
$stmt = $conn->prepare("
    SELECT id, status FROM friend_requests 
    WHERE (requester_id = ? AND requested_id = ?) OR (requester_id = ? AND requested_id = ?)
");
$stmt->bind_param("iiii", $user_id, $friend_id, $friend_id, $user_id);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    // Existing request found, check status
    if ($row['status'] === 'pending') {
        echo json_encode(['success' => false, 'message' => 'Friend request is already pending']);
    } else if ($row['status'] === 'accepted') {
        echo json_encode(['success' => false, 'message' => 'You are already friends']);
    } else {
        // If rejected, allow re-request?
        echo json_encode(['success' => false, 'message' => 'Friend request was rejected previously']);
    }
    $stmt->close();
    $conn->close();
    exit();
}
$stmt->close();

// Insert new friend request with status 'pending'
$stmt = $conn->prepare("INSERT INTO friend_requests (requester_id, requested_id, status) VALUES (?, ?, 'pending')");
$stmt->bind_param("ii", $user_id, $friend_id);

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Friend request sent']);
} else {
    echo json_encode(['success' => false, 'message' => 'Failed to send friend request']);
}

$stmt->close();
$conn->close();
?>
