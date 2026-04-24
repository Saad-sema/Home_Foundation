<?php
require 'config.php';

$result = $conn->query(
    "SELECT Qr_srl, MF_Card_No, Name_Full_name, Address_Area_of_residence,
            Mobile_number_If_possible_WhatsApp, Ration_Card_number,
            Aadhar_Card_number, Qr_String, Is_Consistent
     FROM food_distribution
     ORDER BY Qr_srl ASC"
);

$list = [];
if ($result) {
    while ($row = $result->fetch_assoc()) {
        $list[] = $row;
    }
}

echo json_encode($list);

$conn->close();
?>
