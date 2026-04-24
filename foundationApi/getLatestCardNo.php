<?php
require 'config.php';

// Return the MF_Card_No of the record with the highest numeric value
// We order by Qr_srl DESC to get the latest inserted row
$result = $conn->query("SELECT MF_Card_No FROM food_distribution ORDER BY Qr_srl DESC LIMIT 1");

if ($result && $result->num_rows > 0) {
    $row = $result->fetch_assoc();
    echo json_encode(["success" => true, "latest_card" => $row['MF_Card_No']]);
} else {
    echo json_encode(["success" => false, "latest_card" => ""]);
}

$conn->close();
?>
