<?php
require 'config.php';

// total master
$sqlTotal = "SELECT COUNT(*) AS total_master FROM food_distribution";
$resTotal = $conn->query($sqlTotal);
$rowTotal = $resTotal->fetch_assoc();
$total_master = (int)$rowTotal['total_master'];

// total claimed
$sqlClaimed = "SELECT COUNT(*) AS total_claimed FROM claimed_data";
$resClaimed = $conn->query($sqlClaimed);
$rowClaimed = $resClaimed->fetch_assoc();
$total_claimed = (int)$rowClaimed['total_claimed'];

$remaining = $total_master - $total_claimed;
if ($remaining < 0) $remaining = 0;

echo json_encode([
    "total_master"   => $total_master,
    "total_claimed"  => $total_claimed,
    "remaining"      => $remaining
]);

$conn->close();
?>
