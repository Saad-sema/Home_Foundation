<?php
require 'config.php';

$qr_srl  = isset($_POST['Qr_srl']) ? intval($_POST['Qr_srl']) : 0;
$mf      = isset($_POST['MF_Card_No']) ? $_POST['MF_Card_No'] : '';
$name    = isset($_POST['Name_Full_name']) ? $_POST['Name_Full_name'] : '';
$ration  = isset($_POST['Ration_Card_number']) ? $_POST['Ration_Card_number'] : '';
$aadhar  = isset($_POST['Aadhar_Card_number']) ? $_POST['Aadhar_Card_number'] : '';

if ($qr_srl == 0 || $mf == '' || $name == '') {
    echo json_encode(["success" => false, "message" => "Missing fields"]);
    exit;
}

$stmtCheck = $conn->prepare("SELECT id FROM claimed_data WHERE MF_Card_No = ?");
$stmtCheck->bind_param("s", $mf);
$stmtCheck->execute();
$resCheck = $stmtCheck->get_result();
if ($resCheck->num_rows > 0) {
    echo json_encode(["success" => false, "message" => "Already Claimed"]);
    exit;
}
$stmtCheck->close();

$stmt = $conn->prepare("INSERT INTO claimed_data (Qr_srl, MF_Card_No, Name_Full_name, Ration_Card_number, Aadhar_Card_number) VALUES (?, ?, ?, ?, ?)");
$stmt->bind_param("issss", $qr_srl, $mf, $name, $ration, $aadhar);

if ($stmt->execute()) {
    echo json_encode(["success" => true, "message" => "Claim Successfully Added"]);
} else {
    echo json_encode(["success" => false, "message" => "Insert error"]);
}

$stmt->close();
$conn->close();
?>
