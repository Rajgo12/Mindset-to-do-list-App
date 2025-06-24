<?php
// database.php - Database connection file

$host = '127.0.0.1';  // XAMPP default host
$user = 'root';       // Default MySQL user
$pass = '';           // Default no password
$dbname = 'mindset_db'; // Your actual database name
$port = 3308;         // Your MySQL port

// Create connection
$conn = new mysqli($host, $user, $pass, $dbname, $port);



// Check connection
if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "❌ Connection failed: " . $conn->connect_error]));
}
?>
