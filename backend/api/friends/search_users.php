<?php
require_once '../../config/database.php';

// Get the query parameter from GET request
$query = isset($_GET['query']) ? trim($_GET['query']) : '';

header('Content-Type: application/json');

if ($query === '') {
    echo json_encode([]);
    exit();
}

// Prevent SQL Injection with prepared statements
$likeQuery = '%' . $query . '%';

$stmt = $conn->prepare("
    SELECT id, username, email 
    FROM users 
    WHERE username LIKE ? OR email LIKE ?
    LIMIT 20
");

$stmt->bind_param('ss', $likeQuery, $likeQuery);
$stmt->execute();

$result = $stmt->get_result();

$users = [];

while ($row = $result->fetch_assoc()) {
    $users[] = [
        'id' => (int)$row['id'],
        'username' => $row['username'],
        'email' => $row['email'],
    ];
}

echo json_encode($users);

$stmt->close();
$conn->close();
?>
