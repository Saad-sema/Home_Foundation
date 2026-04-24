<?php
require 'config.php';

// Returns all members in food_distribution who have NOT yet claimed
$sql = "SELECT 
            fd.Qr_srl,
            fd.MF_Card_No,
            fd.Name_Full_name,
            fd.Ration_Card_number,
            fd.Aadhar_Card_number,
            fd.Address_Area_of_residence,
            fd.Mobile_number_If_possible_WhatsApp
        FROM food_distribution fd
        WHERE  NOT EXISTS (
              SELECT 1 FROM claimed_data cd WHERE cd.MF_Card_No = fd.MF_Card_No
          )";

$result = $conn->query($sql);

$rows = [];
while ($row = $result->fetch_assoc()) {
    $rows[] = $row;
}

echo json_encode($rows);
$conn->close();
?>