<?php
require 'config.php';

$mf = isset($_GET['MF_Card_No']) ? $_GET['MF_Card_No'] : '';

if ($mf == '') {
    echo json_encode(["exists" => false, "message" => "MF Card missing"]);
    exit;
}

$stmt = $conn->prepare("SELECT Qr_srl FROM food_distribution WHERE MF_Card_No = ?");
$stmt->bind_param("s", $mf);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    echo json_encode(["exists" => true, "message" => "MF Card already in use"]);
} else {
    echo json_encode(["exists" => false, "message" => "MF Card available"]);
}

$stmt->close();
$conn->close();
?>
