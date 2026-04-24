<?php
require 'config.php';

$ration = isset($_GET['Ration_Card_number']) ? $_GET['Ration_Card_number'] : '';

if ($ration == '') {
    echo json_encode([]);
    exit;
}

$stmt = $conn->prepare("SELECT * FROM food_distribution WHERE Ration_Card_number = ?");
$stmt->bind_param("s", $ration);
$stmt->execute();
$result = $stmt->get_result();

$list = [];
while ($row = $result->fetch_assoc()) {
    $list[] = $row;
}

echo json_encode($list);

$stmt->close();
$conn->close();
?>
