<?php
require 'config.php';

$MF_Card_No = $_POST['MF_Card_No'] ?? '';
$Name = $_POST['Name_Full_name'] ?? '';
$Address = $_POST['Address_Area_of_residence'] ?? '';
$Mobile = $_POST['Mobile_number_If_possible_WhatsApp'] ?? '';
$Ration = $_POST['Ration_Card_number'] ?? '';
$Aadhar = $_POST['Aadhar_Card_number'] ?? '';

if ($MF_Card_No == '' || $Name == '') {
    echo json_encode(["success" => false, "message" => "Missing required fields"]);
    exit;
}

// Generate Qr_srl = '10000' concatenated with MF_Card_No
// e.g. MF_Card_No = 1222  =>  Qr_srl = 100001222
$Qr_srl = '10000' . $MF_Card_No;

// MF unique check
$stmtCheck = $conn->prepare("SELECT Qr_srl FROM food_distribution WHERE MF_Card_No = ?");
$stmtCheck->bind_param("s", $MF_Card_No);
$stmtCheck->execute();
$resCheck = $stmtCheck->get_result();
if ($resCheck->num_rows > 0) {
    echo json_encode(["success" => false, "message" => "MF Card already in use"]);
    exit;
}
$stmtCheck->close();

// Qr_srl unique check (safety guard)
$stmtQrCheck = $conn->prepare("SELECT Qr_srl FROM food_distribution WHERE Qr_srl = ?");
$stmtQrCheck->bind_param("s", $Qr_srl);
$stmtQrCheck->execute();
$resQrCheck = $stmtQrCheck->get_result();
if ($resQrCheck->num_rows > 0) {
    echo json_encode(["success" => false, "message" => "Qr_srl already exists for this card"]);
    exit;
}
$stmtQrCheck->close();

// Build Qr_String = "QR-" . Qr_srl
$Qr_String = "QR_" . $Qr_srl;

// Insert with explicit Qr_srl and Qr_String
$stmt = $conn->prepare("INSERT INTO food_distribution 
    (Qr_srl, MF_Card_No, Name_Full_name, Address_Area_of_residence, Mobile_number_If_possible_WhatsApp, Ration_Card_number, Aadhar_Card_number, Qr_String)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)");

$stmt->bind_param(
    "ssssssss",
    $Qr_srl,
    $MF_Card_No,
    $Name,
    $Address,
    $Mobile,
    $Ration,
    $Aadhar,
    $Qr_String
);

if ($stmt->execute()) {
    echo json_encode([
        "success" => true,
        "message" => "Member inserted",
        "Qr_srl" => $Qr_srl,
        "Qr_String" => $Qr_String
    ]);
} else {
    echo json_encode(["success" => false, "message" => "Insert error: " . $stmt->error]);
}

$stmt->close();
$conn->close();
?>