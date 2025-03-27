class User {
  final String uid;
  final String name;
  final String email;
  final String? password; // Nullable if using Google Login
  final bool googleLogin;
  final String profilePic;
  final bool audioEnabled;
  final bool notificationEnabled;
  final String qrCode;
  final String referralCode;
  final String status;
  final DateTime createdDate;
  final DateTime lastUpdateDate;

  User({
    required this.uid,
    required this.name,
    required this.email,
    this.password,
    required this.googleLogin,
    required this.profilePic,
    required this.audioEnabled,
    required this.notificationEnabled,
    required this.qrCode,
    required this.referralCode,
    required this.status,
    required this.createdDate,
    required this.lastUpdateDate,
  });

  // Factory constructor to create a User object from a Map (e.g., Firestore document)
  factory User.fromMap(Map<String, dynamic> map, String documentId) {
    return User(
      uid: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'],
      googleLogin: map['googleLogin'] ?? false,
      profilePic: map['profilePic'] ?? '',
      audioEnabled: map['audioEnabled'] ?? false,
      notificationEnabled: map['notificationEnabled'] ?? false,
      qrCode: map['qrCode'] ?? '',
      referralCode: map['referralCode'] ?? '',
      status: map['status'] ?? 'inactive',
      createdDate: DateTime.parse(
        map['createdDate'] ?? DateTime.now().toIso8601String(),
      ),
      lastUpdateDate: DateTime.parse(
        map['lastUpdateDate'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  // Method to convert a User object to a Map (e.g., for Firestore document)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'googleLogin': googleLogin,
      'profilePic': profilePic,
      'audioEnabled': audioEnabled,
      'notificationEnabled': notificationEnabled,
      'qrCode': qrCode,
      'referralCode': referralCode,
      'status': status,
      'createdDate': createdDate.toIso8601String(),
      'lastUpdateDate': lastUpdateDate.toIso8601String(),
    };
  }
}
