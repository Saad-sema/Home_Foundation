<?php
require 'config.php';

$qr = isset($_GET['qr']) ? $_GET['qr'] : '';

if ($qr == '') {
    echo json_encode(null);
    exit;
}

$stmt = $conn->prepare("SELECT * FROM food_distribution WHERE Qr_String = ?");
$stmt->bind_param("s", $qr);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    echo json_encode($row);
} else {
    echo json_encode(null);
}

$stmt->close();
$conn->close();
?>
