<?php
require 'config.php';

$mf = isset($_GET['MF_Card_No']) ? $_GET['MF_Card_No'] : '';

if ($mf == '') {
    echo json_encode(["success" => false, "message" => "MF Card missing"]);
    exit;
}

// Force IST so the claimed_at TIMESTAMP is returned in local time
$conn->query("SET time_zone = '+05:30'");

$stmt = $conn->prepare("SELECT id, claimed_at FROM claimed_data WHERE MF_Card_No = ?");
$stmt->bind_param("s", $mf);
$stmt->execute();
$result = $stmt->get_result();


if ($result->num_rows > 0) {
    $row = $result->fetch_assoc();
    // Format claimed_at in 12-hour format
    $claimed_at_raw = $row['claimed_at'];
    $claimed_at_12h = '';
    if ($claimed_at_raw) {
        $dt = new DateTime($claimed_at_raw);
        $claimed_at_12h = $dt->format('d M Y, h:i A');
    }
    echo json_encode(["success" => false, "message" => "Already Claimed", "claimed_at" => $claimed_at_12h]);
} else {
    echo json_encode(["success" => true, "message" => "You Can Claim", "claimed_at" => null]);
}

$stmt->close();
$conn->close();
?>
