class MyUser {
  final String uid;
  final String name;
  final String email;
  final String? password; // Nullable if using Google Login
  final bool googleLogin;
  final String profilePic;
  final String qrCode;
  final String referralCode;
  final int status; // ✅ Changed to integer (1 = active, 0 = inactive)
  final DateTime createdDate;
  final DateTime lastUpdateDate;

  MyUser({
    required this.uid,
    required this.name,
    required this.email,
    this.password,
    required this.googleLogin,
    required this.profilePic,
    required this.qrCode,
    required this.referralCode,
    required this.status, // ✅ Integer status
    required this.createdDate,
    required this.lastUpdateDate,
  });

  // ✅ Convert Firestore data to MyUser object
  factory MyUser.fromMap(Map<String, dynamic> map, String documentId) {
    return MyUser(
      uid: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'],
      googleLogin: map['googleLogin'] ?? false,
      profilePic: map['profilePic'] ?? '',
      qrCode: map['qrCode'] ?? '',
      referralCode: map['referralCode'] ?? '',
      status:
          (map['status'] as num?)?.toInt() ??
          0, // ✅ Converts Firestore value safely
      createdDate:
          DateTime.tryParse(map['createdDate'] ?? '') ?? DateTime.now(),
      lastUpdateDate:
          DateTime.tryParse(map['lastUpdateDate'] ?? '') ?? DateTime.now(),
    );
  }

  // ✅ Convert MyUser object to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'googleLogin': googleLogin,
      'profilePic': profilePic,
      'qrCode': qrCode,
      'referralCode': referralCode,
      'status': status, // ✅ Stores as integer
      'createdDate': createdDate.toIso8601String(),
      'lastUpdateDate': lastUpdateDate.toIso8601String(),
    };
  }
}
