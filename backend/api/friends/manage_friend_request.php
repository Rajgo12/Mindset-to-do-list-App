<?php
require_once '../../config/database.php';
header('Content-Type: application/json');

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);

    $action = $data['action'] ?? '';
    $user_id = isset($data['user_id']) ? (int)$data['user_id'] : 0;
    $requester_id = isset($data['requester_id']) ? (int)$data['requester_id'] : 0;

    if (!$user_id) {
        echo json_encode(['success' => false, 'message' => 'Missing user_id']);
        exit();
    }

    if ($action === 'accept') {
        if (!$requester_id) {
            echo json_encode(['success' => false, 'message' => 'Missing requester_id']);
            exit();
        }

        // Update friend_requests status to accepted
        $stmt = $conn->prepare("UPDATE friend_requests SET status='accepted' WHERE requester_id=? AND requested_id=? AND status='pending'");
        $stmt->bind_param("ii", $requester_id, $user_id);
        $success = $stmt->execute();
        $stmt->close();

        if ($success) {
            // Insert into friends table (user1_id < user2_id)
            $user1 = min($user_id, $requester_id);
            $user2 = max($user_id, $requester_id);

            $stmt = $conn->prepare("INSERT IGNORE INTO friends (user1_id, user2_id) VALUES (?, ?)");
            $stmt->bind_param("ii", $user1, $user2);
            $success = $stmt->execute();
            $stmt->close();
        }

        echo json_encode(['success' => $success]);
        exit();

    } elseif ($action === 'reject') {
        if (!$requester_id) {
            echo json_encode(['success' => false, 'message' => 'Missing requester_id']);
            exit();
        }

        // Update friend_requests status to rejected
        $stmt = $conn->prepare("UPDATE friend_requests SET status='rejected' WHERE requester_id=? AND requested_id=? AND status='pending'");
        $stmt->bind_param("ii", $requester_id, $user_id);
        $success = $stmt->execute();
        $stmt->close();

        echo json_encode(['success' => $success]);
        exit();

    } elseif ($action === 'get_requests') {
        // Get incoming friend requests where user is requested_id and status is pending
        $stmt = $conn->prepare("
            SELECT fr.id AS id, u.id AS requester_id, u.username, u.email
            FROM friend_requests fr
            JOIN users u ON fr.requester_id = u.id
            WHERE fr.requested_id = ? AND fr.status = 'pending'
        ");
        $stmt->bind_param("i", $user_id);
        $stmt->execute();
        $result = $stmt->get_result();

        $requests = [];
        while ($row = $result->fetch_assoc()) {
            $requests[] = $row;
        }
        $stmt->close();

        echo json_encode(['success' => true, 'requests' => $requests]);
        exit();
    }

    echo json_encode(['success' => false, 'message' => 'Invalid or missing action']);
    exit();
}

echo json_encode(['success' => false, 'message' => 'Invalid request method']);
$conn->close();
?>
