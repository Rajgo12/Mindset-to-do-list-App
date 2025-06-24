<?php
require_once '../../config/database.php';
header('Content-Type: application/json');

// Read the incoming JSON request body
$data = json_decode(file_get_contents("php://input"));

// Validate input
if (!isset($data->user_id) || !isset($data->friend_id)) {
    http_response_code(400); // Bad Request
    echo json_encode(['success' => false, 'message' => 'Missing required fields']);
    exit();
}

$user_id = (int)$data->user_id;
$friend_id = (int)$data->friend_id;

// Start a transaction
$conn->begin_transaction();

try {
    // Delete the friend relationship
    $stmt1 = $conn->prepare("
        DELETE FROM friends 
        WHERE (user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?)
    ");
    if (!$stmt1) {
        throw new Exception("Failed to prepare friends delete statement");
    }

    $stmt1->bind_param("iiii", $user_id, $friend_id, $friend_id, $user_id);
    $stmt1->execute();
    $deletedFriends = $stmt1->affected_rows;
    $stmt1->close();

    // Delete any friend requests between the two users
    $stmt2 = $conn->prepare("
        DELETE FROM friend_requests
        WHERE (requester_id = ? AND requested_id = ?) OR (requester_id = ? AND requested_id = ?)
    ");
    if (!$stmt2) {
        throw new Exception("Failed to prepare friend_requests delete statement");
    }

    $stmt2->bind_param("iiii", $user_id, $friend_id, $friend_id, $user_id);
    $stmt2->execute();
    $deletedRequests = $stmt2->affected_rows;
    $stmt2->close();

    // Commit transaction
    $conn->commit();

    if ($deletedFriends > 0 || $deletedRequests > 0) {
        echo json_encode([
            'success' => true,
            'message' => 'Friend and any friend requests deleted successfully'
        ]);
    } else {
        http_response_code(404); // Not Found
        echo json_encode([
            'success' => false,
            'message' => 'No friend relationship or request found'
        ]);
    }
} catch (Exception $e) {
    $conn->rollback();
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Transaction failed: ' . $e->getMessage()]);
}

$conn->close();
