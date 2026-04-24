<?php
require 'config.php';

// Force IST timezone for this session so TIMESTAMP columns read correctly
$conn->query("SET time_zone = '+05:30'");

// Returns all claimed members with their claimed_at time in 12-hour IST format
$sql = "SELECT 
            cd.Qr_srl,
            cd.MF_Card_No,
            cd.Name_Full_name,
            cd.Ration_Card_number,
            cd.Aadhar_Card_number,
            DATE_FORMAT(cd.claimed_at, '%d %b %Y, %h:%i %p') AS claimed_at_fmt
        FROM claimed_data cd
        ORDER BY cd.claimed_at DESC";

$result = $conn->query($sql);

$rows = [];
while ($row = $result->fetch_assoc()) {
    $rows[] = $row;
}

echo json_encode($rows);
$conn->close();
?>
