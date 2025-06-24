<?php
require_once '../../config/database.php';

$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
if (!$user_id) {
    echo json_encode(['success' => false, 'message' => 'Missing user_id']);
    exit;
}

// Get all collaborations for this user
$sql = "
    SELECT 
        c.id, c.task_item_id, ti.task_id, t.title AS task_title,
        ti.title AS task_item_title,
        u1.username AS collaborator_name, u2.username AS requested_name,
        c.collaborator_id, c.requested_id, c.status, c.created_at
    FROM collaboration c
    JOIN task_item ti ON c.task_item_id = ti.id
    JOIN tasks t ON ti.task_id = t.id
    JOIN users u1 ON c.collaborator_id = u1.id
    JOIN users u2 ON c.requested_id = u2.id
    WHERE (c.collaborator_id = ? OR c.requested_id = ?)
    ORDER BY c.created_at DESC
";
$stmt = $conn->prepare($sql);
$stmt->bind_param("ii", $user_id, $user_id);
$stmt->execute();
$result = $stmt->get_result();

$accepted_collaborations = [];
$pending_collaborations = [];

while ($row = $result->fetch_assoc()) {
    // Only include accepted users in collaboration_with
    $req_sql = "SELECT u.id, u.username FROM collaboration c2 JOIN users u ON c2.requested_id = u.id WHERE c2.task_item_id = ? AND c2.status = 'accepted'";
    $req_stmt = $conn->prepare($req_sql);
    $req_stmt->bind_param("i", $row['task_item_id']);
    $req_stmt->execute();
    $req_result = $req_stmt->get_result();
    $requested_users = [];
    while ($r = $req_result->fetch_assoc()) {
        $requested_users[] = $r;
    }
    $req_stmt->close();

    $row['collaborated_by'] = $row['collaborator_name'];
    $row['collaboration_with'] = $requested_users;

    if ($row['status'] === 'accepted') {
        $accepted_collaborations[] = $row;
    } elseif ($row['status'] === 'pending') {
        $pending_collaborations[] = $row;
    }
}
$stmt->close();

echo json_encode([
    'success' => true,
    'accepted_collaborations' => $accepted_collaborations,
    'pending_collaborations' => $pending_collaborations,
]);