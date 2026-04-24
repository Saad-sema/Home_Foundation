class FoodRecord {
  final int qrSrl;
  final String mfCardNo;
  final String name;
  final String rationCard;
  final String aadhar;
  final String address;
  final String mobile;
  final String qrString;
  final String isConsistent;

  FoodRecord({
    required this.qrSrl,
    required this.mfCardNo,
    required this.name,
    required this.rationCard,
    required this.aadhar,
    required this.address,
    this.mobile = '',
    this.qrString = '',
    this.isConsistent = '',
  });

  factory FoodRecord.fromJson(Map<String, dynamic> json) {
    return FoodRecord(
      qrSrl: int.tryParse(json['Qr_srl'].toString()) ?? 0,
      mfCardNo: json['MF_Card_No'] ?? '',
      name: json['Name_Full_name'] ?? '',
      rationCard: json['Ration_Card_number'] ?? '',
      aadhar: json['Aadhar_Card_number'] ?? '',
      address: json['Address_Area_of_residence'] ?? '',
      mobile: json['Mobile_number_If_possible_WhatsApp'] ?? '',
      qrString: json['Qr_String'] ?? '',
      isConsistent: json['Is_Consistent'] ?? '',
    );
  }

  FoodRecord copyWith({
    int? qrSrl,
    String? mfCardNo,
    String? name,
    String? rationCard,
    String? aadhar,
    String? address,
    String? mobile,
    String? qrString,
    String? isConsistent,
  }) {
    return FoodRecord(
      qrSrl: qrSrl ?? this.qrSrl,
      mfCardNo: mfCardNo ?? this.mfCardNo,
      name: name ?? this.name,
      rationCard: rationCard ?? this.rationCard,
      aadhar: aadhar ?? this.aadhar,
      address: address ?? this.address,
      mobile: mobile ?? this.mobile,
      qrString: qrString ?? this.qrString,
      isConsistent: isConsistent ?? this.isConsistent,
    );
  }
}
