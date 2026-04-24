<?php
require 'config.php';

$type = isset($_GET['type']) ? $_GET['type'] : '';

$column = '';
switch ($type) {
    case 'aadhaar':
        $column = 'Aadhar_Card_number';
        break;
    case 'card_no':
        $column = 'MF_Card_No';
        break;
    case 'ration':
        $column = 'Ration_Card_number';
        break;
    case 'name':
        $column = 'Name_Full_name';
        break;
    default:
        echo json_encode(["success" => false, "message" => "Invalid duplicate type"]);
        exit;
}

// Optimization: Subquery to find values that appear more than once
$sql = "SELECT Qr_srl, MF_Card_No, Name_Full_name, Address_Area_of_residence, 
               Mobile_number_If_possible_WhatsApp, Ration_Card_number, 
               Aadhar_Card_number, Qr_String, Is_Consistent
        FROM food_distribution 
        WHERE $column IN (
            SELECT $column FROM food_distribution 
            WHERE $column != '' AND $column IS NOT NULL
            GROUP BY $column 
            HAVING COUNT(*) > 1
        )
        ORDER BY $column ASC, Qr_srl ASC";

$result = $conn->query($sql);

$list = [];
if ($result) {
    while ($row = $result->fetch_assoc()) {
        $list[] = $row;
    }
}

echo json_encode($list);

$conn->close();
?>
