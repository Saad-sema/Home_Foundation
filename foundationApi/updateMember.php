<?php
require 'config.php';

header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

$qr_srl  = isset($_POST['Qr_srl'])                                    ? trim($_POST['Qr_srl'])                                      : '';
$mf      = isset($_POST['MF_Card_No'])                                ? trim($_POST['MF_Card_No'])                                  : '';
$name    = isset($_POST['Name_Full_name'])                              ? trim($_POST['Name_Full_name'])                                : '';
$address = isset($_POST['Address_Area_of_residence'])                 ? trim($_POST['Address_Area_of_residence'])                   : '';
$mobile  = isset($_POST['Mobile_number_If_possible_WhatsApp'])        ? trim($_POST['Mobile_number_If_possible_WhatsApp'])          : '';
$ration  = isset($_POST['Ration_Card_number'])                        ? trim($_POST['Ration_Card_number'])                          : '';
$aadhar  = isset($_POST['Aadhar_Card_number'])                        ? trim($_POST['Aadhar_Card_number'])                          : '';
$consistent = isset($_POST['Is_Consistent'])                          ? trim($_POST['Is_Consistent'])                                : '';

if ($qr_srl == '' || $mf == '' || $name == '') {
    echo json_encode(["success" => false, "message" => "Missing required fields (Qr_srl, MF_Card_No, Name)"]);
    exit;
}

$ignoreConflict = isset($_POST['ignore_conflict']) && $_POST['ignore_conflict'] === 'true';

// Duplicate ration card check
if ($ration != '' && !$ignoreConflict) {
    $stmtRation = $conn->prepare(
        "SELECT Qr_srl, Name_Full_name, MF_Card_No FROM food_distribution WHERE Ration_Card_number = ? AND Qr_srl != ?"
    );
    $stmtRation->bind_param("ss", $ration, $qr_srl);
    $stmtRation->execute();
    $resRation = $stmtRation->get_result();
    if ($resRation->num_rows > 0) {
        $conflict = $resRation->fetch_assoc();
        echo json_encode([
            "success" => false, 
            "error_type" => "duplicate",
            "message" => "Duplicate ration card: This number is already assigned.",
            "conflict_member" => [
                "name" => $conflict['Name_Full_name'],
                "mf_card" => $conflict['MF_Card_No']
            ]
        ]);
        $stmtRation->close();
        $conn->close();
        exit;
    }
    $stmtRation->close();
}

// Perform the update
$stmt = $conn->prepare(
    "UPDATE food_distribution SET
        MF_Card_No = ?,
        Name_Full_name = ?,
        Address_Area_of_residence = ?,
        Mobile_number_If_possible_WhatsApp = ?,
        Ration_Card_number = ?,
        Aadhar_Card_number = ?,
        Is_Consistent = ?
     WHERE Qr_srl = ?"
);
$stmt->bind_param("ssssssss",
    $mf,
    $name,
    $address,
    $mobile,
    $ration,
    $aadhar,
    $consistent,
    $qr_srl
);

if ($stmt->execute()) {
    if ($stmt->affected_rows >= 0) {
        echo json_encode(["success" => true, "message" => "Member updated successfully."]);
    } else {
        echo json_encode(["success" => false, "message" => "No record found with given Qr_srl."]);
    }
} else {
    echo json_encode(["success" => false, "message" => "Update error: " . $stmt->error]);
}

$stmt->close();
$conn->close();
?>
