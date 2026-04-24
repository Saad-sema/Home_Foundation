<?php
require 'config.php';

$field = isset($_GET['field']) ? $_GET['field'] : '';
$value = isset($_GET['value']) ? $_GET['value'] : '';

$allowed = ["MF_Card_No", "Ration_Card_number", "Aadhar_Card_number"];
if (!in_array($field, $allowed) || $value == '') {
    echo json_encode([]);
    exit;
}

$sql = "SELECT * FROM food_distribution WHERE $field = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $value);
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
